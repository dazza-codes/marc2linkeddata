
# Marc21 Authority fields are documented at
# http://www.loc.gov/marc/authority/ecadlist.html
# http://www.loc.gov/marc/authority/ecadhome.html

require_relative 'boot'
require_relative 'loc'
require_relative 'viaf'

module Marc2LinkedData

  class ParseMarcAuthority

    # TODO: provide iterator pattern on an entire file of records.
    # @leader = ParseMarcAuthority::parse_leader(marc_file)
    # raw = marc_file.read(@leader[:length])
    # @record = MARC::Reader.decode(raw)


    def initialize(record)
      @record = record
      @config = Marc2LinkedData.configuration
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
      begin
        # 922 is the ISNI IRI, e.g. http://www.isni.org/0000000109311081
        field922 = @record.fields.select {|f| f if f.tag == '922' }.first
        get_iri(field922, 'isni.org')
      rescue
        nil
      end
    end

    def get_iri4loc
      begin
        # 920 is the loc IRI,  e.g. http://id.loc.gov/authorities/names/n42000906
        field920 = @record.fields.select {|f| f if f.tag == '920' }.first
        get_iri(field920, 'id.loc.gov')
      rescue
        nil
      end
    end

    def get_iri4lib
      "#{@config.prefixes['lib']}authority/#{get_id}"
    end

    def get_iri4viaf
      begin
        # 921 is the viaf IRI, e.g. http://viaf.org/viaf/181829329
        # Note VIAF RSS feed for changes, e.g. http://viaf.org/viaf/181829329.rss
        field921 = @record.fields.select {|f| f if f.tag == '921' }.first
        get_iri(field921, 'viaf.org')
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
        'MISSING_PERSONAL_NAME'
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
        'MISSING_PERSONAL_NAME'
      end
    end

    def to_ttl
      # http://www.loc.gov/marc/authority/adintro.html
      triples = []
      lib_auth_key = 'lib_auth'
      lib = get_iri4lib.gsub(@config.prefixes[lib_auth_key], "#{lib_auth_key}:")
      # Try to find LOC, VIAF, and ISNI IRIs in the MARC record
      loc = Loc.new get_iri4loc
      isni_iri = get_iri4isni
      viaf = Viaf.new get_iri4viaf

      # Get LOC control number and add catalog permalink? e.g.
      # http://lccn.loc.gov/n79046291

      if loc.iri.nil?
        # Always try to determine the LOC IRI
        url = nil
        if loc.id =~ /^n/i
          url = "#{@config.prefixes['loc_names']}#{loc.id.downcase}"
        end
        if loc.id =~ /^sh/i
          url = "#{@config.prefixes['loc_subjects']}#{loc.id.downcase}"
        end
        unless url.nil?
          # Verify the URL
          res = Marc2LinkedData.http_head_request(url + '.rdf')
          case res.code
            when '200'
              loc = Loc.new url
            when '301'
              loc = Loc.new res['location']
            when '302','303'
              #302 Moved Temporarily
              #303 See Other
              # Use the current URL, most get requests will follow a 302 or 303
              loc = Loc.new url
          end
          puts "DISCOVERED: #{loc.iri}" unless loc.iri.nil?
        end
      end

      unless loc.iri.nil?
        if viaf.iri.nil? #&& ENV['MARC_GET_VIAF']
          # Try to get VIAF via LOC.
          viaf = Viaf.new loc.get_viaf
        end
        if isni_iri.nil? #&& ENV['MARC_GET_ISNI']
          # Try to get ISNI via VIAF.
          isni_iri = viaf.get_isni
        end
      end


      if loc.iri.to_s =~ /name/
        # The MARC data differentiates them according to the tag number.
        # The term 'name' refers to:
        #  X00 - Personal Name
        #  X10 - Corporate Name
        #  X11 - Meeting Name
        #  X30 - Uniform Title
        #  X51 - Jurisdiction / Geographic Name
        #
        puts "LOC URL: #{loc.iri} DEPRECATED" if loc.deprecated?
        name = ''
        if loc.person?
          name = parse_100
          triples << "#{lib} a foaf:Person"
        end
        if loc.corporation?
          name = parse_110
          triples << "#{lib} a foaf:Organization"
        end
        if name == ''
          triples << "#{lib} a foaf:Agent"  # Fallback
          # TODO: find out what type this is.
          binding.pry if CONFIG.debug
        else
          name_encoding = URI.encode(name)
          triples << "; foaf:name \"#{name_encoding}\""
        end
        triples << "; owl:sameAs loc_names:#{loc.id}"
        unless viaf.iri.nil?
          triples << "; owl:sameAs viaf:#{viaf.id}"
        end
        unless isni_iri.nil?
          isni_id = URI.parse(isni_iri).path.gsub('isni/','').gsub('/','')
          triples << "; owl:sameAs isni:#{isni_id}"
        end
        triples << " .\n"
      elsif loc.iri.to_s =~ /subjects/
        # TODO: what to do with subjects?
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
        #triples << "#{lib} a foaf:Person" # TODO: what type is this?
        #triples << "; owl:sameAs #{loc_iri.gsub(PREFIX_LOC_SUBJECTS, 'loc_subjects:')}"
      else
        binding.pry if CONFIG.debug
      end
      puts "Extracted #{loc.id}" if CONFIG.debug
      # Interesting case: a person was an Organisation - President of Chile.
      #binding.pry if viaf_iri =~ /80486556/
      triples.join
    end
  end

end

