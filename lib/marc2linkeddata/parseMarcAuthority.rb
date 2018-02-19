
# Marc21 Authority fields are documented at
# http://www.loc.gov/marc/authority/ecadlist.html
# http://www.loc.gov/marc/authority/ecadhome.html

module Marc2LinkedData

  class ParseMarcAuthority

    @@config = nil

    attr_reader :file_path
    attr_reader :file_offset
    attr_reader :marc
    attr_reader :record
    attr_reader :auth_type

    attr_reader :id
    attr_reader :iri
    attr_reader :loc
    attr_reader :isni
    attr_reader :viaf

    def initialize(record)
      @@config ||= Marc2LinkedData.configuration
      @file_path = record[:filepath]
      @file_offset = record[:offset]
      @marc = record[:marc]
      @record = record
      @auth_type = auth_type
      @graph = RDF::Graph.new
      @id = nil
      @iri = nil
      @loc = nil
      @isni = nil
      @viaf = nil
    end

    # Try to use the SUL catkey and/or the OCLC control numbers, maybe SUL
    # catkey in the record IRI
    def id
      # extract ID from control numbers, see
      # http://www.loc.gov/marc/authority/ad001.html
      #field001 = marc.fields.select {|f| f if f.tag == '001' }.first.value
      #field003 = marc.fields.select {|f| f if f.tag == '003' }.first.value
      #"#{field003}-#{field001}"
      @id ||= get_fields(@@config.field_auth_id).first.value
    end

    def iri
      @iri ||= "#{@@config.prefixes['lib_auth']}#{id}"
    end

    def entity
      @entity ||= begin
        case auth_type
        when :person
          Marc2LinkedData::Resource.new(iri + '#Person')
        when :name_title
          Marc2LinkedData::Resource.new(iri + '#NameTitle')
        when :corporation
          Marc2LinkedData::Resource.new(iri + '#Organization')
        when :conference
          Marc2LinkedData::Resource.new(iri + '#Conference')
        when :uniform_title
          Marc2LinkedData::Resource.new(iri + '#UniformTitle')
        when :geographic
          Marc2LinkedData::Resource.new(iri + '#Place')
        else
          Marc2LinkedData::Resource.new(iri + '#RWO')
        end
      end
    end

    def auth_type
      @auth_type ||= begin
        if person?
          :person
        elsif name_title?
          :name_title
        elsif corporation?
          :corporation
        elsif conference?
          :conference
        elsif uniform_title?
          :uniform_title
        elsif geographic?
          :geographic
        else
          # TODO: find out what type this is.
          binding.pry if @@config.debug
          nil
        end
      end
    end

    def label
      @label ||= begin
        case auth_type
        when :person
          field100[:name].strip
        when :name_title
          field100[:name].strip
        when :corporation
          field110[:name].strip
        when :conference
          [field111[:name],field111[:date],field111[:city]].join('')
        when :uniform_title
          field130[:title].strip # use 'name' for code below, although it's a title
        when :geographic
          field151[:name].strip  # use 'name' for code below, although it's a place
        else
          nil
        end
      end
    end

    def first_name
      @first_name ||= begin
        if person?
          field100[:name].split(',')[1].strip rescue nil
        else
          nil
        end
      end
    end

    def last_name
      @last_name ||= begin
        if person?
          field100[:name].split(',')[0].strip rescue nil
        else
          nil
        end
      end
    end


    # BLOCK ----------------------------------------------------
    # IRI extraction from fields


    def get_iri(field, iri_pattern)
      begin
        iris = field.subfields.collect {|f| f.value if f.value.include? iri_pattern }
        iris.first || nil
      rescue
        nil
      end
    end

    def get_iri4isni
      isni_iri = nil
      begin
        # e.g. http://www.isni.org/0000000109311081
        field = get_fields(@@config.field_auth_isni).first
        isni_iri = get_iri(field, 'isni.org')
        # If ISNI is not already in the MARC record, try to get it from VIAF.
        if isni_iri.nil? && @@config.get_isni
          isni_iri = @viaf.get_isni rescue nil
          # binding.pry if @viaf.iri.to_s.include? '67737121' #@@config.debug
        end
        isni_iri = fix_iri4isni(isni_iri)
        @@config.logger.debug 'Failed to resolve ISNI URI' if isni_iri.nil?
        return isni_iri
      rescue
        nil
      end
    end

    # Ensure the ISNI IRI has this prefix: http://www.isni.org/isni/
    def fix_iri4isni(iri)
      return nil if iri.nil?
      iri.sub('www.isni.org', 'www.isni.org/isni') unless iri.include? 'www.isni.org/isni/'
    end

    def get_iri4loc
      loc_iri = nil
      begin
        # e.g. http://id.loc.gov/authorities/names/n42000906
        field = get_fields(@@config.field_auth_loc).first
        loc_iri = get_iri(field, 'id.loc.gov')
      rescue
      end
      begin
        if loc_iri.nil?
          # If the LOC is not in the marc record, try to determine the LOC IRI from the ID.
          loc_id = id
          if loc_id =~ /^n/i
            loc_iri = "#{@@config.prefixes['loc_names']}#{loc_id.downcase}"
          end
          if loc_id =~ /^sh/i
            loc_iri = "#{@@config.prefixes['loc_subjects']}#{loc_id.downcase}"
          end
          unless loc_iri.nil?
            # Verify the URL (used HEAD so it's as fast as possible)
            @@config.logger.debug "Trying to validate LOC IRI: #{loc_iri}"
            loc_iri = Marc2LinkedData.http_head_request(loc_iri + '.rdf')
          end
          if loc_iri.nil?
            # If it gets here, it's a problem.
            binding.pry if @@config.debug
            @@config.logger.error "FAILURE to resolve LOC IRI: #{loc_id}"
          else
            @@config.logger.debug "DISCOVERED LOC IRI: #{loc_iri}"
          end
        else
          @@config.logger.debug "MARC contains LOC IRI: #{loc_iri}"
        end
        return loc_iri
      rescue
        nil
      end
    end

    def get_iri4oclc
      begin
        field = get_fields(@@config.field_auth_oclc).first
        oclc_cn = field.subfields.collect {|f| f.value if f.code == 'a'}.first
        oclc_id = /\d+$/.match(oclc_cn).to_s
        oclc_id.empty? ? nil : "http://www.worldcat.org/oclc/#{oclc_id}"
      rescue
        nil
      end
    end

    def get_iri4viaf
      begin
        # e.g. http://viaf.org/viaf/181829329
        # VIAF RSS feed for changes, e.g. http://viaf.org/viaf/181829329.rss
        field = get_fields(@@config.field_auth_viaf).first
        viaf_iri = get_iri(field, 'viaf.org')
        # If VIAF is not already in the MARC record, try to get it from LOC.
        if viaf_iri.nil? && @@config.get_viaf
          viaf_iri = @loc.get_viaf rescue nil
          @@config.logger.debug 'Failed to resolve VIAF URI' if viaf_iri.nil?
        end
        return viaf_iri
      rescue
        nil
      end
    end


    # BLOCK ----------------------------------------------------
    # Parse fields

    def get_fields(field_num)
      fields = @marc.fields.select {|f| f if f.tag == field_num }
      raise "Invalid data in field #{field_num}" if fields.length < 1
      fields
    end

    # 008 - Fixed-Length Data Elements
    # http://www.loc.gov/marc/authority/concise/ad008.html
    def parse_008
      field = get_fields('008').first
      field008 = field.value
      languages = []
      languages.append('English') if ['b','e'].include? field008[8]
      languages.append('French') if ['b','f'].include? field008[8]
      rules = ''
      rules = 'EARLIER' if field008[10] == 'a'
      rules = 'AACR1' if field008[10] == 'b'
      rules = 'AACR2' if field008[10] == 'c'
      rules = 'AACR2 compatible' if field008[10] == 'd'
      rules = 'OTHER' if field008[10] == 'z'
      rules = 'N/A' if field008[10] == 'n'
      # 32 - Undifferentiated personal name
      # Whether the personal name in a name or name/title heading contained in field 100 in an established heading record or a reference record is used by one person or by two or more persons.
      # a - Differentiated personal name
      #     Personal name in field 100 is a unique name.
      # b - Undifferentiated personal name
      #     Personal name in field 100 is used by two or more persons.
      # n - Not applicable
      #     1XX heading is not a personal name or the personal name is a family name.
      # | - No attempt to code
      {
          :date => Date.strptime(field008[0..5], "%y%m%d"),
          :geographic_subdivision => field008[6], # '#', d, i, n, or '|'
          :romanization_scheme => field008[7], # a..g, n, or '|'
          :languages => languages,
          :kind => field008[9], # a..g, or '|'
          :rules => rules,
          :heading_system => field008[11],
          :series_type => field008[12],
          :series_numbered => field008[13],
          :use_1XX_for_7XX => field008[14] == 'a',
          :use_1XX_for_6XX => field008[15] == 'a',
          :use_1XX_for_4XX => field008[16] == 'a',
          :use_1XX_for_8XX => field008[16] == 'a',
          :type_subject_subdivision => field008[17],
          # 18-27 - Undefined character positions
          :type_government_agency => field008[28],
          :reference_evaluation => field008[29],
          # 30 - Undefined character position
          :record_available => field008[31] == 'a',
          # TODO: 32
          # TODO: 33
          # 34-37 - Undefined character positions
          # TODO: 38
          # TODO: 39
      }
    end

    # 100 - Heading-Personal Name
    # http://www.loc.gov/marc/authority/concise/ad100.html
    def field100
      # [#<MARC::Subfield:0x007f009d6a74e0 @code="a", @value="Abe, Eiichi,">,
      #     #<MARC::Subfield:0x007f009d6a7440 @code="d", @value="1927-">,
      #     #<MARC::Subfield:0x007f009d6a73a0 @code="t", @value="Hoppu dais\xC5\xAB.">,
      #     #<MARC::Subfield:0x007f009d6a7300 @code="l", @value="English">],
      #     @tag="100">
      begin
        # 100 is a personal name or name-title
        return @field100 unless @field100.nil?
        field = get_fields('100').first
        name = field.subfields.select {|f| f.code == 'a' }.first.value rescue ''
        date = field.subfields.select {|f| f.code == 'd' }.first.value rescue ''
        title = field.subfields.select {|f| f.code == 't' }.first.value rescue ''
        lang = field.subfields.select {|f| f.code == 'l' }.first.value rescue ''
        name = name.gsub(/,$/,'')
        @field100 = {
            :name => name.force_encoding('UTF-8'),
            :date => date,
            :title => title.force_encoding('UTF-8'),
            :lang => lang,
            :error => nil
        }
      rescue => e
        @@config.logger.debug "Failed to parse field 100 for #{id}: #{e.message}"
        @field100 = {
            :name => nil,
            :date => nil,
            :title => nil,
            :lang => nil,
            :error => 'ERROR_PERSON_NAME' #e.message
        }
      end
    end

    # 110 - Heading-Corporate Name
    # http://www.loc.gov/marc/authority/concise/ad110.html
    def field110
      begin
        # 110 is a corporate name
        return @field110 unless @field110.nil?
        field = get_fields('110').first
        a = field.subfields.collect {|f| f.value if f.code == 'a' }.compact rescue []
        b = field.subfields.collect {|f| f.value if f.code == 'b' }.compact rescue []
        c = field.subfields.collect {|f| f.value if f.code == 'c' }.compact rescue []
        name = [a,b,c].flatten.join(' ')
        @field110 = {
            :name => name.force_encoding('UTF-8'),
            :error => nil
        }
      rescue => e
        @@config.logger.debug "Failed to parse field 110 for #{id}: #{e.message}"
        @field110 = {
            :name => nil,
            :error => 'ERROR_CORPORATE_NAME' #e.message
        }
      end
    end

    # 111 - Heading-Meeting Name
    # http://www.loc.gov/marc/authority/concise/ad111.html
    def field111
      # #<MARC::Subfield:0x007f43a50fd1e8 @code="a", @value="Joseph Priestley Symposium">,
      # #<MARC::Subfield:0x007f43a50fd148 @code="d", @value="(1974 :">,
      # #<MARC::Subfield:0x007f43a50fd0a8 @code="c", @value="Wilkes-Barre, Pa.)">],
      # @tag="111">,
      begin
        return @field111 unless @field111.nil?
        field = get_fields('111').first
        name = field.subfields.select {|f| f.code == 'a' }.first.value rescue ''
        date = field.subfields.select {|f| f.code == 'd' }.first.value rescue ''
        city = field.subfields.select {|f| f.code == 'c' }.first.value rescue ''
        @field111 = {
            :name => name.force_encoding('UTF-8'),
            :date => date,
            :city => city.force_encoding('UTF-8'),
            :error => nil
        }
      rescue => e
        @@config.logger.debug "Failed to parse field 111 for #{id}: #{e.message}"
        @field111 = {
            :name => nil,
            :date => nil,
            :city => nil,
            :error => 'ERROR_MEETING_NAME'
        }
      end
    end

    # 130 - Heading-Uniform Title
    # http://www.loc.gov/marc/authority/concise/ad130.html
    def field130
      # e.g. http://id.loc.gov/authorities/names/n79119331
      # #<MARC::DataField:0x007f7f6bffe708
      # @indicator1=" ",
      # @indicator2="0",
      # @subfields=[#<MARC::Subfield:0x007f7f6bffe208 @code="a", @value="Fair maid of the Exchange">],
      # @tag="130">,
      # plus a lot of 400 fields
      begin
        return @field130 unless @field130.nil?
        field = get_fields('130').first
        title = field.subfields.collect {|f| f.value if f.code == 'a'}.first rescue ''
        @field130 = {
            :title => title.force_encoding('UTF-8'),
            :error => nil
        }
      rescue => e
        @@config.logger.debug "Failed to parse field 130 for #{id}: #{e.message}"
        @field130 = {
            :title => nil,
            :error => 'ERROR_UNIFORM_TITLE'
        }
      end
    end

    # 151 - Heading-Geographic Name
    # http://www.loc.gov/marc/authority/concise/ad151.html
    def field151
      # e.g. http://id.loc.gov/authorities/names/n79045127
      begin
        return @field151 unless @field151.nil?
        field = get_fields('151').first
        name = field.subfields.collect {|f| f.value if f.code == 'a' }.first rescue ''
        @field151 = {
            :name => name.force_encoding('UTF-8'),
            :error => nil
        }
      rescue => e
        @@config.logger.debug "Failed to parse field 151 for #{id}: #{e.message}"
        @field151 = {
            :name => nil,
            :error => 'ERROR_PLACE_NAME'
        }
      end
    end


    # BLOCK ----------------------------------------------------
    # Authority record types

    # TODO: other authority types?
    # The MARC data differentiates them according to the tag number.
    # Methods below ordered by field number.

    #  X00 - Personal Name
    def person?
      field = field100
      field[:error].nil? && (! field[:name].empty?) && field[:title].empty?
    end

    #  X00 - Name-Title
    def name_title?
      # e.g. http://id.loc.gov/authorities/names/n79044934
      # if id == 'n79044934'.upcase
      #   binding.pry if @@config.debug
      # end
      field = field100
      field[:error].nil? && (! field[:name].empty?) && (! field[:title].empty?)
    end

    #  X10 - Corporate Name
    def corporation?
      field110[:error].nil?
    end

    #  X11 - Meeting Name
    def conference?
      # e.g. http://id.loc.gov/authorities/names/n79044866
      field111[:error].nil?
    end

    #  X30 - Uniform Title
    def uniform_title?
      field130[:error].nil?
    end

    #  X51 - Jurisdiction / Geographic Name
    #      - http://www.loc.gov/mads/rdf/v1#Geographic
    def geographic?
      # e.g. http://id.loc.gov/authorities/names/n79046135.html
      field151[:error].nil?
    end

    # BLOCK ----------------------------------------------------
    # Parse authority record

    def parse_auth_details
      if @loc.nil?
        # There is no LOC authority record, so parse MARC without RDF.
        parse_auth_name
      elsif @loc.iri.to_s =~ /name/
        if @@config.get_loc
          # Retrieve and use LOC RDF
          parse_auth_name_rdf
        else
          # Use only the MARC record
          parse_auth_name
        end
      elsif @loc.iri.to_s =~ /subjects/
        # TODO: what to do with subjects?
        # http://id.loc.gov/authorities/subjects
        #
        binding.pry if @@config.debug
        # parse_auth_subject_rdf
      else
        # What is this?
        binding.pry if @@config.debug
      end
    end


    # BLOCK ----------------------------------------------------
    # Parse authority record without RDF

    def parse_auth_name
      #
      # Create triples for various kinds of LOC authority.
      #
      s = entity.rdf_uri
      name = label
      case auth_type
      when :person
        graph_type_person(s)
        # # TODO: try to get a language type?
        # # name = RDF::Literal.new(n, :language => :en)
        ln = last_name
        unless ln.nil?
          o = RDF::Literal.new(ln)
          @graph << [s, RDF::Vocab::FOAF.familyName,   o] if @@config.use_foaf
          @graph << [s, RDF::Vocab::SCHEMA.familyName, o] if @@config.use_schema
        end
        # # TODO: try to get a language type?
        # # name = RDF::Literal.new(n, :language => :en)
        fn = first_name
        unless fn.nil?
          o = RDF::Literal.new(fn)
          @graph << [s, RDF::Vocab::FOAF.firstName,   o] if @@config.use_foaf
          @graph << [s, RDF::Vocab::SCHEMA.givenName, o] if @@config.use_schema
        end
      when :name_title
        # can this be an entity?  Should be a Work?
        # http://viaf.org/viaf/182251325/rdf.xml
        o = RDF::URI.new('http://www.loc.gov/mads/rdf/v1#NameTitle')
        graph_insert_type(s, o)
      when :corporation
        graph_type_organization(s)
      when :conference
        # e.g. http://id.loc.gov/authorities/names/n79044866
        o = RDF::Vocab::SCHEMA.event
        graph_insert_type(s, o)
      when :uniform_title
        # can this be an entity?  Should be a Work?
        graph_insert_type(s, RDF::URI.new('http://www.loc.gov/mads/rdf/v1#Title'))
        graph_insert_type(s, RDF::Vocab::SCHEMA.title)
      when :geographic
        graph_insert_type(s, RDF::Vocab::SCHEMA.Place)
      else
        # TODO: find out what type this is.
        binding.pry if @@config.debug
        graph_type_agent(s)
      end
      unless name.nil?
        name = RDF::Literal.new(name)
        graph_insert_name(s, name)
      end
    end


    # BLOCK ----------------------------------------------------
    # Parse authority record using RDF

    # Create triples for various kinds of LOC authority.
    # This method relies on RDF data retrieval.
    def parse_auth_name_rdf
      @@config.logger.warn "#{@loc.iri} DEPRECATED" if @loc.deprecated?
      s = entity.rdf_uri
      name = ''
      if @loc.person?
        name = @loc.label || field100[:name]
        graph_type_person(s)
        # VIAF extracts first and last name, try to use them. Note
        # that VIAF uses schema:name, schema:givenName, and schema:familyName.
        if @@config.get_viaf && ! @viaf.nil?
          @viaf.family_names.each do |n|
            # ln = URI.encode(n)
            # TODO: try to get a language type, if VIAF provide it.
            # name = RDF::Literal.new(n, :language => :en)
            ln = RDF::Literal.new(n)
            @graph.insert RDF::Statement(s, RDF::Vocab::FOAF.familyName, ln) if @@config.use_foaf
            @graph.insert RDF::Statement(s, RDF::Vocab::SCHEMA.familyName, ln) if @@config.use_schema
          end
          @viaf.given_names.each do |n|
            # fn = URI.encode(n)
            # TODO: try to get a language type, if VIAF provide it.
            # name = RDF::Literal.new(n, :language => :en)
            fn = RDF::Literal.new(n)
            @graph.insert RDF::Statement(s, RDF::Vocab::FOAF.firstName, fn) if @@config.use_foaf
            @graph.insert RDF::Statement(s, RDF::Vocab::SCHEMA.givenName, fn) if @@config.use_schema
          end
        end
      elsif @loc.name_title?
        # e.g. http://id.loc.gov/authorities/names/n79044934
        # http://viaf.org/viaf/182251325/rdf.xml
        name = @loc.label || field100[:name]
        graph_insert_type(s, RDF::URI.new('http://www.loc.gov/mads/rdf/v1#NameTitle'))
      elsif @loc.corporation?
        name = @loc.label || field110[:name]
        graph_type_organization(s)
      elsif @loc.conference?
        # e.g. http://id.loc.gov/authorities/names/n79044866
        name = @loc.label || [field111[:name],field111[:date],field111[:city]].join('')
        graph_insert_type(s, RDF::Vocab::SCHEMA.event)
      elsif @loc.geographic?
        # e.g. http://id.loc.gov/authorities/names/n79045127
        name = @loc.label || field151[:name]
        graph_insert_type(s, RDF::Vocab::SCHEMA.Place)
      elsif @loc.uniform_title?
        name = field130[:title]  # use 'name' for code below, although it's a title
        graph_insert_type(s, RDF::URI.new('http://www.loc.gov/mads/rdf/v1#Title'))
        graph_insert_type(s, RDF::Vocab::SCHEMA.title)
      else
        # TODO: find out what type this is.
        binding.pry if @@config.debug
        name = @loc.label || ''
        graph_type_agent(s)
      end
      if name != ''
        name = RDF::Literal.new(name)
        graph_insert_name(s, name)
      end
    end

    def parse_auth_subject_rdf
      # LCSH?
      # The term 'subject' refers to:
      #  X30 - Uniform Titles
      #  X48 - Chronological Terms
      #  X50 - Topical Terms
      #  X51 - Geographic Names
      #  X55 - Genre/Form Terms
      #
      # The term 'subject subdivision' refers to:
      # X80 - general subdivision terms
      # X81 - geographic subdivision names
      # X82 - chronological subdivision terms
      # X85 - form subdivision terms
      #
      # It's worth emphasising the point made in the penultimate sentence: not
      # all concepts "have a focus"; some concepts are "just concepts" (poetry,
      # slavery, conscientious objection, anarchism etc etc etc).
      #
      # For example,
      #
      # @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
      # @prefix skos: <http://www.w3.org/2004/02/skos/core#> .
      # @prefix lcsh: <http://id.loc.gov/authorities/subjects/> .
      # lcsh:sh85089767 a skos:Concept ;
      #   rdfs:label "Napoleonic Wars, 1800-1815"@en ;
      #   skos:prefLabel "Napoleonic Wars, 1800-1815"@en ;
      #   skos:altLabel "Napoleonic Wars, 1800-1814"@en ;
      #   skos:broader lcsh:sh85045703 ;
      #   skos:narrower lcsh:sh85144863 ;
      #   skos:inScheme <http://id.loc.gov/authorities/subjects> .
      #
    end

    def get_oclc_links
      # Try to get OCLC using LOC ID.
      oclc_iri = @loc.get_oclc_identity rescue nil
      # Try to get OCLC using 035a field data, but
      # this is not as reliable/accurate as LOC.
      oclc_iri ||= get_iri4oclc
      unless oclc_iri.nil?
        # Try to get additional data from OCLC, using the RDFa
        # available in the OCLC identities pages.
        oclc_auth = OclcIdentity.new oclc_iri

        graph_insert_closeMatch(oclc_auth.rdf_uri, @lib.rdf_uri)
        graph_insert_closeMatch(oclc_auth.rdf_uri, @loc.rdf_uri) unless @loc.nil?
        graph_insert_closeMatch(oclc_auth.rdf_uri, @viaf.uri_record) unless @viaf.nil?

        graph_insert_foafFocus(oclc_auth.rdf_uri, entity.rdf_uri)
        graph_insert_foafFocus(oclc_auth.rdf_uri, @viaf.uri_entity) unless @viaf.nil?
        graph_insert_foafFocus(oclc_auth.rdf_uri, @isni.rdf_uri) unless @isni.nil?

        oclc_auth.creative_works.each do |creative_work_uri|
          creative_work = OclcCreativeWork.new creative_work_uri
          graph_insert_seeAlso(oclc_auth.rdf_uri, creative_work.rdf_uri)
          graph_insert_seeAlso(creative_work.rdf_uri, oclc_auth.rdf_uri)
          creative_work.iri_types.each do |type|
            graph_insert_type(creative_work.rdf_uri, type)
          end
          if creative_work.name
            predicates = [
              # RDF::Vocab::SCHEMA.name,
              # RDF::Vocab::SKOS.prefLabel,
              RDF::RDFS.label
            ]
            predicates.each do |p|
              graph_insert(creative_work.rdf_uri, p, creative_work.name)
            end
          end
          creative_work.isbns.each do |isbn|
            p = RDF::Vocab::SCHEMA.isbn
            graph_insert(creative_work.rdf_uri, p, isbn)
          end
          creative_work.fast.each do |fast|
            p = RDF::Vocab::SCHEMA.about
            graph_insert(creative_work.rdf_uri, p, fast)
          end
          if @@config.oclc_auth2works
            # Try to use VIAF to relate auth to work as creator, contributor, editor, etc.
            # Note that this requires additional RDF retrieval for each work (slower processing).
            unless @viaf.nil?
              if creative_work.creator? @viaf.uri_entity
                graph_insert_creator(creative_work.rdf_uri, oclc_auth.rdf_uri)
                graph_insert_creator(creative_work.rdf_uri, @viaf.uri_entity)
                graph_insert_creator(creative_work.rdf_uri, entity.rdf_uri)
              elsif creative_work.contributor? @viaf.uri_entity
                graph_insert_contributor(creative_work.rdf_uri, oclc_auth.rdf_uri)
                graph_insert_contributor(creative_work.rdf_uri, @viaf.uri_entity)
                graph_insert_contributor(creative_work.rdf_uri, entity.rdf_uri)
              elsif creative_work.editor? @viaf.uri_entity
                graph_insert_editor(creative_work.rdf_uri, oclc_auth.rdf_uri)
                graph_insert_editor(creative_work.rdf_uri, @viaf.uri_entity)
                graph_insert_editor(creative_work.rdf_uri, entity.rdf_uri)
              end
            end
            # TODO: Is auth the subject of the work (as in biography) or both (as in autobiography)?
            # binding.pry if @@config.debug
            # binding.pry if creative_work.iri.to_s == 'http://www.worldcat.org/oclc/006626542'
            # Try to find the generic work entity for this example work.
            creative_work.get_works.each do |oclc_work_uri|
              oclc_work = OclcWork.new oclc_work_uri
              graph_insert_exampleOfWork(creative_work.rdf_uri, oclc_work.rdf_uri)
            end
          end
        end
      end
    end

    # TODO: use an institutional 'affiliation' entry, maybe 373?  (optional field)

    # BLOCK ----------------------------------------------------
    # Graph methods

    def to_ttl
      graph.to_ttl
    end

    def graph
      return @graph unless @graph.empty?
      @lib = LibAuth.new iri
      # Create authority records as foaf:Document or schema:Report
      graph_type_document(@lib.rdf_uri)
      graph_insert_foafFocus(@lib.rdf_uri, entity.rdf_uri)
      # Try to find LOC, VIAF, and ISNI IRIs in the MARC record
      @loc = Loc.new get_iri4loc rescue nil
      if @loc.nil?
        # Try to identify problems in getting an LOC IRI.
        binding.pry if @@config.debug
      else
        graph_type_document(@loc.rdf_uri)
        graph_insert_closeMatch(@lib.rdf_uri, @loc.rdf_uri)
        @loc.sameAs.each do |same_as|
          graph_insert_sameAs(@loc.rdf_uri, same_as)
        end
        @loc.seeAlso.each do |see_also|
          graph_insert_seeAlso(@loc.rdf_uri, see_also)
        end
      end
      # might require LOC to get ISNI.
      @viaf = Viaf.new get_iri4viaf rescue nil
      unless @viaf.nil?
        # VIAF URIs are an authority record when they end with '/', but
        # without it they are an entity of some kind.
        graph_type_document(@viaf.uri_record)
        graph_insert_foafFocus(@viaf.uri_record, @viaf.uri_entity)
        graph_insert_foafFocus(@lib.rdf_uri, @viaf.uri_entity)
        graph_insert_closeMatch(@lib.rdf_uri, @viaf.uri_record)
        graph_insert_closeMatch(entity.rdf_uri, @viaf.uri_entity)
        @viaf.sameAs.each do |same_as|
          graph_insert_sameAs(@viaf.rdf_uri, same_as)
        end
        @viaf.seeAlso.each do |see_also|
          graph_insert_seeAlso(@viaf.rdf_uri, see_also)
        end
      end
      # might require VIAF to get ISNI.
      @isni = Isni.new get_iri4isni rescue nil
      unless @isni.nil?
        # ISNI URIs are an entity of some kind.
        graph_insert_foafFocus(@lib.rdf_uri, @isni.rdf_uri)
        graph_insert_closeMatch(entity.rdf_uri, @isni.rdf_uri)
      end

      # TODO: ORCID? Stanford CAP? Harvard Profiles?  WikiData?
      # http://vladimiralexiev.github.io/CH-names/readme.html
      # http://efoundations.typepad.com/efoundations/2011/09/things-their-conceptualisations-skos-foaffocus-modelling-choices.html

      # Construct authority entity
      parse_auth_details
      # Optional elaboration of authority data with OCLC identity and works.
      get_oclc_links if @@config.get_oclc
      @graph
    end

    def graph_insert(uriS, uriP, uriO)
      @graph.insert RDF::Statement(uriS, uriP, uriO)
    end
    def graph_insert_sameAs(uriS, uriO)
      graph_insert(uriS, RDF::OWL.sameAs, uriO)
    end
    def graph_insert_closeMatch(uriS, uriO)
      graph_insert(uriS, RDF::Vocab::SKOS.closeMatch, uriO)
    end
    def graph_insert_seeAlso(uriS, uriO)
      graph_insert(uriS, RDF::RDFS.seeAlso, uriO)
    end
    def graph_insert_creator(uriS, uriO)
      graph_insert(uriS, RDF::Vocab::SCHEMA.creator, uriO)
    end
    def graph_insert_contributor(uriS, uriO)
      graph_insert(uriS, RDF::Vocab::SCHEMA.contributor, uriO)
    end
    def graph_insert_editor(uriS, uriO)
      graph_insert(uriS, RDF::Vocab::SCHEMA.editor, uriO)
    end
    def graph_insert_exampleOfWork(uriS, uriO)
      graph_insert(uriS, RDF::Vocab::SCHEMA.exampleOfWork, uriO)
    end
    def graph_insert_foafFocus(uriS, uriO)
      # http://xmlns.com/foaf/spec/#term_focus
      # relates SKOS:Concept to a 'real world thing'
      graph_insert(uriS, RDF::Vocab::FOAF.focus, uriO)
    end
    def graph_insert_name(uriS, name)
      graph_insert(uriS, RDF::Vocab::FOAF.name, name) if @@config.use_foaf
      graph_insert(uriS, RDF::Vocab::SCHEMA.name, name) if @@config.use_schema
    end

    # ----
    # Methods that assert RDF.type

    def graph_insert_type(uriS, uriO)
      graph_insert(uriS, RDF.type, uriO)
    end

    def graph_type_agent(uriS)
      # Note: schema.org has no immediate parent for Person or Organization
      graph_insert_type(uriS, RDF::Vocab::FOAF.Agent) if @@config.use_foaf
      graph_insert_type(uriS, RDF::Vocab::SCHEMA.Thing) if @@config.use_schema
    end

    def graph_type_concept(uriS)
      graph_insert_type(uriS, RDF::Vocab::SKOS.Concept)
    end

    def graph_type_document(uriS)
      graph_insert_type(uriS, RDF::Vocab::FOAF.Document) if @@config.use_foaf
      graph_insert_type(uriS, RDF::Vocab::SCHEMA.Report) if @@config.use_schema
    end

    def graph_type_organization(uriS)
      graph_insert_type(uriS, RDF::Vocab::FOAF.Organization) if @@config.use_foaf
      graph_insert_type(uriS, RDF::Vocab::SCHEMA.Organization) if @@config.use_schema
    end

    def graph_type_person(uriS)
      graph_insert_type(uriS, RDF::Vocab::FOAF.Person) if @@config.use_foaf
      graph_insert_type(uriS, RDF::Vocab::SCHEMA.Person) if @@config.use_schema
    end
  end

end

