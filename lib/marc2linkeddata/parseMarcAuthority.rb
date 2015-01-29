
# Marc21 Authority fields are documented at
# http://www.loc.gov/marc/authority/ecadlist.html
# http://www.loc.gov/marc/authority/ecadhome.html

module Marc2LinkedData

  class ParseMarcAuthority

    # TODO: provide iterator pattern on an entire file of records.
    # @leader = ParseMarcAuthority::parse_leader(marc_file)
    # raw = marc_file.read(@leader[:length])
    # @record = MARC::Reader.decode(raw)

    @@config = nil

    attr_reader :loc
    attr_reader :isni
    attr_reader :viaf

    def initialize(record)
      @@config ||= Marc2LinkedData.configuration
      @record = record
      @graph = RDF::Graph.new
      @loc = nil
      @isni = nil
      @viaf = nil
    end

    # Try to use the SUL catkey and/or the OCLC control numbers, maybe SUL
    # catkey in the record IRI
    def get_id
      # extract ID from control numbers, see
      # http://www.loc.gov/marc/authority/ad001.html
      #field001 = record.fields.select {|f| f if f.tag == '001' }.first.value
      #field003 = record.fields.select {|f| f if f.tag == '003' }.first.value
      #"#{field003}-#{field001}"
      @record.fields.select {|f| f if f.tag == '001' }.first.value
    end

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
        # 922 is the ISNI IRI, e.g. http://www.isni.org/0000000109311081
        field922 = @record.fields.select {|f| f if f.tag == '922' }.first
        isni_iri = get_iri(field922, 'isni.org')
        # If ISNI is not already in the MARC record, try to get it from VIAF.
        if isni_iri.nil? && @@config.get_isni
          isni_iri = @viaf.get_isni rescue nil
          @@config.logger.debug 'Failed to resolve ISNI URI' if isni_iri.nil?
          # binding.pry if @viaf.iri.to_s.include? '67737121' #@@config.debug
        end
        unless isni_iri.nil?
          # Ensure the ISNI IRI has this prefix: http://www.isni.org/isni/
          isni_iri.gsub('www.isni.org', 'www.isni.org/isni') unless isni_iri =~ /www\.isni\.org\/isni\//
        end
        return isni_iri
      rescue
        nil
      end
    end

    def get_iri4lib
      "#{@@config.prefixes['lib_auth']}#{get_id}"
    end

    def get_iri4loc
      loc_iri = nil
      begin
        # 920 is the loc IRI,  e.g. http://id.loc.gov/authorities/names/n42000906
        field920 = @record.fields.select {|f| f if f.tag == '920' }.first
        loc_iri = get_iri(field920, 'id.loc.gov')
        if loc_iri.nil?
          # If the LOC is not in the marc record, try to determine the LOC IRI from the ID.
          loc_id = get_id
          if loc_id =~ /^n/i
            loc_iri = "#{@@config.prefixes['loc_names']}#{loc_id.downcase}"
          end
          if loc_id =~ /^sh/i
            loc_iri = "#{@@config.prefixes['loc_subjects']}#{loc_id.downcase}"
          end
          unless loc_iri.nil?
            # Verify the URL (used HEAD so it's as fast as possible)
            res = Marc2LinkedData.http_head_request(loc_iri + '.rdf')
            case res.code
              when '200'
                # it's good to go
              when '301'
                # use the redirection
                loc_iri = res['location']
              when '302','303'
                #302 Moved Temporarily
                #303 See Other
                # Use the current URL, most get requests will follow a 302 or 303
              else
                loc_iri = nil
            end
          end
          if loc_iri.nil?
            # If it gets here, it's a problem.
            binding.pry if @@config.debug
            @@config.logger.error 'FAILURE to resolve LOC URL'
          else
            @@config.logger.debug "DISCOVERED: #{loc_iri}"
          end
        else
          @@config.logger.debug "MARC contains LOC: #{loc_iri}"
        end
        return loc_iri
      rescue
        nil
      end
    end

    def get_iri4oclc
      begin
        # 035 is the OCLC control number
        field = @record.fields.select {|f| f if f.tag == '035' }.first
        oclc_cn = field.subfields.collect {|f| f.value if f.code == 'a'}.first
        oclc_id = /\d+$/.match(oclc_cn).to_s
        oclc_id.empty? ? nil : "http://www.worldcat.org/oclc/#{oclc_id}"
      rescue
        nil
      end
    end

    def get_iri4viaf
      begin
        # 921 is the viaf IRI, e.g. http://viaf.org/viaf/181829329
        # Note VIAF RSS feed for changes, e.g. http://viaf.org/viaf/181829329.rss
        field921 = @record.fields.select {|f| f if f.tag == '921' }.first
        viaf_iri = get_iri(field921, 'viaf.org')
        # If VIAF is not already in the MARC record, try to get from LOC.
        if viaf_iri.nil? && @@config.get_viaf
          viaf_iri = @loc.get_viaf rescue nil
          @@config.logger.debug 'Failed to resolve VIAF URI' if viaf_iri.nil?
        end
        return viaf_iri
      rescue
        nil
      end
    end

    def self.parse_leader(file_handle, leader_bytes=24)
      # example:
      #record.leader
      #=> "00774cz  a2200253n  4500"
      # 00-04: '00774' - record length
      # 05:    'c' - corrected or revised
      # 06:    'z' - always 'z' for authority records
      # 09:    'a' - UCS/Unicode
      # 12-16: '00253' - base address of data, Length of Leader and Directory
      # 17:    'n' - Complete authority record
      leader_status_codes = {
          'a' => 'Increase in encoding level',
          'c' => 'Corrected or revised',
          'd' => 'Deleted',
          'n' => 'New',
          'o' => 'Obsolete',
          's' => 'Deleted; heading split into two or more headings',
          'x' => 'Deleted; heading replaced by another heading'
      }
      leader = file_handle.read(leader_bytes)
      file_handle.seek(-1 * leader_bytes, IO::SEEK_CUR)
      {
          :length => leader[0..4].to_i,
          :status => leader[5],  # leader_status_codes[ record.leader[5] ]
          :type => leader[6],    # always 'z' for authority records
          :encoding => leader[9],  # translate letter code into ruby encoding string
          :data_address => leader[12..16].to_i,
          :complete => leader[17].include?('n')
      }
    end

    def parse_008
      # http://www.loc.gov/marc/authority/concise/ad008.html
      field008 = @record.fields.select {|f| f if f.tag == '008' }
      raise 'Invalid data in field008' if field008.length != 1
      field008 = field008.first.value
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

    def parse_100
      # http://www.loc.gov/marc/authority/concise/ad100.html
      begin
        # 100 is a personal name
        field = @record.fields.select {|f| f if f.tag == '100' }.first
        name = field.subfields.select {|f| f.code == 'a' }.first.value rescue ''
        name.force_encoding('UTF-8')
      rescue
        'ERROR_PERSONAL_NAME'
      end
    end

    def parse_110
      # http://www.loc.gov/marc/authority/concise/ad110.html
      begin
        # 110 is a corporate name
        field = @record.fields.select {|f| f if f.tag == '110' }.first
        a = field.subfields.collect {|f| f.value if f.code == 'a' }.compact rescue []
        b = field.subfields.collect {|f| f.value if f.code == 'b' }.compact rescue []
        c = field.subfields.collect {|f| f.value if f.code == 'c' }.compact rescue []
        name = [a,b,c].flatten.join(' : ')
        name.force_encoding('UTF-8')
      rescue
        'ERROR_CORPORATE_NAME'
      end
    end

    def parse_111
      # http://www.loc.gov/marc/authority/concise/ad111.html
      begin
        # 111 is a meeting name
        field = @record.fields.select {|f| f if f.tag == '111' }.first
        a = field.subfields.collect {|f| f.value if f.code == 'a' }.compact rescue []
        # TODO: incorporate additional subfields?
        # b = field.subfields.collect {|f| f.value if f.code == 'b' }.compact rescue []
        # c = field.subfields.collect {|f| f.value if f.code == 'c' }.compact rescue []
        # name = [a,b,c].flatten.join(' : ')
        # name.force_encoding('UTF-8')
        a.force_encoding('UTF-8')
      rescue
        'ERROR_MEETING_NAME'
      end
    end

    def parse_151
      # http://www.loc.gov/marc/authority/concise/ad151.html
      begin
        # 151 is a geographic name
        field = @record.fields.select {|f| f if f.tag == '151' }.first
        name = field.subfields.collect {|f| f.value if f.code == 'a' }.first rescue ''
        name.force_encoding('UTF-8')
      rescue
        'ERROR_PLACE_NAME'
      end
    end


    # TODO: use an 'affiliation' entry, maybe 373?  (optional field)

    # TODO: construct an RDF::Graph so it can be serialized in different formats.

    # TODO: try to find persons in Stanford CAP data.

    def to_ttl
      graph.to_ttl
    end

    def graph
      # TODO: figure out how to specify all the graph prefixes.
      return @graph unless @graph.empty?
      @lib = LibAuth.new get_iri4lib
      # Try to find LOC, VIAF, and ISNI IRIs in the MARC record
      @loc = Loc.new get_iri4loc rescue nil
      # Try to identify problems in getting an LOC IRI.
      binding.pry if (@@config.debug && @loc.nil?)
      # might require LOC to get ISNI.
      @viaf = Viaf.new get_iri4viaf rescue nil
      # might require VIAF to get ISNI.
      @isni = Isni.new get_iri4isni rescue nil

      # TODO: ORCID? VIVO? VITRO? Stanford CAP?

      # Get LOC control number and add catalog permalink? e.g.
      # http://lccn.loc.gov/n79046291

      @graph.insert RDF::Statement(@lib.rdf_uri, RDF::OWL.sameAs, @loc.rdf_uri)
      @graph.insert RDF::Statement(@lib.rdf_uri, RDF::OWL.sameAs, @viaf.rdf_uri) unless @viaf.nil?
      @graph.insert RDF::Statement(@lib.rdf_uri, RDF::OWL.sameAs, @isni.rdf_uri) unless @isni.nil?
      return @graph unless @@config.get_loc

      # TODO: find codes in the marc record to differentiate the authority into
      # TODO: person, organization, event, etc. without getting LOC RDF.

      #
      # Create triples for various kinds of LOC authority.
      # At present, this relies on LOC RDF to differentiate
      # types of authorities.  It should be possible to do this
      # from the MARC directly, if @@config.get_loc is false.
      #
      if @loc.iri.to_s =~ /name/
        # The MARC data differentiates them according to the tag number.
        # The term 'name' refers to:
        #  X00 - Personal Name
        #  X10 - Corporate Name
        #  X11 - Meeting Name
        #  X30 - Uniform Title
        #  X51 - Jurisdiction / Geographic Name
        #
        @@config.logger.warn "LOC URL: #{@loc.iri} DEPRECATED" if @loc.deprecated?
        name = ''
        if @loc.conference?
          # e.g. http://id.loc.gov/authorities/names/n79044866
          name = @loc.label || parse_111
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::SCHEMA.event)
        elsif @loc.corporation?
          name = @loc.label || parse_110
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::FOAF.Organization) if @@config.use_foaf
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::SCHEMA.Organization) if @@config.use_schema
        elsif @loc.name_title?
          # e.g. http://id.loc.gov/authorities/names/n79044934
          # Skipping these, because the person entity should be in
          # an additional record and we don't want the title content.
          binding.pry if @@config.debug
          return ''
        elsif @loc.person?
          name = @loc.label || parse_100
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::FOAF.Person) if @@config.use_foaf
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::SCHEMA.Person) if @@config.use_schema
          # VIAF extracts first and last name, try to use them. Note
          # that VIAF uses schema:name, schema:givenName, and schema:familyName.
          if @@config.get_viaf && ! @viaf.nil?
            @viaf.family_names.each do |n|
              # ln = URI.encode(n)
              # TODO: try to get a language type, if VIAF provide it.
              # name = RDF::Literal.new(n, :language => :en)
              ln = RDF::Literal.new(n)
              @graph.insert RDF::Statement(@lib.rdf_uri, RDF::FOAF.familyName, ln) if @@config.use_foaf
              @graph.insert RDF::Statement(@lib.rdf_uri, RDF::SCHEMA.familyName, ln) if @@config.use_schema
            end
            @viaf.given_names.each do |n|
              # fn = URI.encode(n)
              # TODO: try to get a language type, if VIAF provide it.
              # name = RDF::Literal.new(n, :language => :en)
              fn = RDF::Literal.new(n)
              @graph.insert RDF::Statement(@lib.rdf_uri, RDF::FOAF.firstName, fn) if @@config.use_foaf
              @graph.insert RDF::Statement(@lib.rdf_uri, RDF::SCHEMA.givenName, fn) if @@config.use_schema
            end
          end
        elsif @loc.place?
          # e.g. http://id.loc.gov/authorities/names/n79045127
          name = @loc.label || parse_151
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::SCHEMA.Place)
        else
          # TODO: find out what type this is.
          binding.pry if @@config.debug
          name = @loc.label || ''
          # Note: schema.org has no immediate parent for Person or Organization
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::FOAF.Agent) if @@config.use_foaf
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF.type, RDF::SCHEMA.Thing) if @@config.use_schema
        end

        if name != ''
          # name_encoding = URI.encode(name)
          name = RDF::Literal.new(name)
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF::FOAF.name, name) if @@config.use_foaf
          @graph.insert RDF::Statement(@lib.rdf_uri, RDF::SCHEMA.name, name) if @@config.use_schema
        end

      elsif @loc.iri.to_s =~ /subjects/
        # TODO: what to do with subjects?
        binding.pry if @@config.debug
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
      else
        binding.pry if @@config.debug
      end

      # Optional elaboration of authority data with OCLC identity and works.
      if @@config.get_oclc
        oclc_iri = nil
        begin
          # Try to get OCLC using LOC ID.
          oclc_iri = @loc.get_oclc_identity
        rescue
          # Try to get OCLC using 035a field data, but
          # this is not as reliable/accurate as LOC.
          oclc_iri = get_iri4oclc
        end
        unless oclc_iri.nil?
          # Try to get additional data from OCLC, using the RDFa
          # available in the OCLC identities pages.
          oclc_auth = OclcIdentity.new oclc_iri
          @graph.insert RDF::Statement(@loc.rdf_uri, RDF::OWL.sameAs, oclc_auth.rdf_uri)
          oclc_auth.creative_works.each do |creative_work_uri|
            # Notes on work-around for OCLC data inconsistency:
            # RDFa for http://www.worldcat.org/identities/lccn-n79044798 contains:
            # <http://worldcat.org/oclc/747413718> a <http://schema.org/CreativeWork> .
            # However, the RDF for <http://worldcat.org/oclc/747413718> contains:
            # <http://www.worldcat.org/oclc/747413718> schema:exampleOfWork <http://worldcat.org/entity/work/id/994448191> .
            # Note how the subject here is 'WWW.worldcat.org' instead of 'worldcat.org'.
            #creative_work_iri = creative_work.to_s.gsub('worldcat.org','www.worldcat.org')
            #creative_work_iri = creative_work_iri.gsub('wwwwww','www') # in case it gets added already by OCLC
            creative_work = OclcCreativeWork.new creative_work_uri
            @graph.insert RDF::Statement(oclc_auth.rdf_uri, RDF::RDFS.seeAlso, creative_work.rdf_uri)
            if @@config.oclc_auth2works
              # Try to use VIAF to relate auth to work as creator, contributor, editor, etc.
              # Note that this requires additional RDF retrieval for each work (slower processing).
              unless @viaf.nil?
                if creative_work.creator? @viaf.iri
                  @graph.insert RDF::Statement(creative_work.rdf_uri, RDF::SCHEMA.creator, oclc_auth.rdf_uri)
                elsif creative_work.contributor? @viaf.iri
                  @graph.insert RDF::Statement(creative_work.rdf_uri, RDF::SCHEMA.contributor, oclc_auth.rdf_uri)
                elsif creative_work.editor? @viaf.iri
                  @graph.insert RDF::Statement(creative_work.rdf_uri, RDF::SCHEMA.editor, oclc_auth.rdf_uri)
                end
              end

              # TODO: Is auth the subject of the work (as in biography) or both (as in autobiography).
              # binding.pry if @@config.debug
              # binding.pry if creative_work.iri.to_s == 'http://www.worldcat.org/oclc/006626542'

              # Try to find the generic work entity for this example work.
              creative_work.get_works.each do |oclc_work_uri|
                oclc_work = OclcWork.new oclc_work_uri
                @graph.insert RDF::Statement(creative_work.rdf_uri, RDF::SCHEMA.exampleOfWork, oclc_work.rdf_uri)
              end
            end

          end
        end

      end

      @@config.logger.info "Extracted #{@loc.id}"
      @graph
    end
  end

end

