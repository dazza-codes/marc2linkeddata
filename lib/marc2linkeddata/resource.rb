
module Marc2LinkedData

  class Resource

    attr_accessor :iri
    # attr_reader :config

    @@config = nil

    def initialize(uri=nil)
      @@config ||= Marc2LinkedData.configuration
      if uri =~ /\A#{URI::regexp}\z/
        uri = Addressable::URI.parse(uri.to_s) rescue nil
      end
      # Strip off any trailing '/'
      if uri.to_s.end_with? '/'
        uri = uri.to_s.gsub(/\/$/,'')
        uri = Addressable::URI.parse(uri.to_s) rescue nil
      end
      raise 'invalid uri' unless uri.instance_of? Addressable::URI
      @iri = uri
    end

    def id
      @iri.basename
    end

    # This method is often overloaded in subclasses because
    # RDF services use variations in the URL 'extension' patterns; e.g.
    # see Loc#rdf and Viaf#rdf
    def rdf
      return @rdf unless @rdf.nil?
      # TODO: try to retrieve the rdf from a local triple store
      # TODO: if local triple store fails, try remote source(s)
      # TODO: if retrieved from a remote source, save the rdf to a local triple store
      @rdf = get_rdf(@iri.to_s)
    end

    def get_rdf(uri4rdf)
      tries = 0
      begin
        tries += 1
        @rdf = RDF::Graph.load(uri4rdf)
      rescue
        retry if tries <= 2
        binding.pry if @@config.debug
        nil
      end
    end

    def rdf_uri
      RDF::URI.new(@iri)
    end

    def rdf_valid?
      iri_types.length > 0
    end

    def iri_types
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> a ?o }")
      rdf.query(q)
    end

    def rdf_find_object(id)
      # TODO: convert this to an RDF.rb graph query?
      return nil unless rdf_valid?
      rdf.each_statement do |s|
        if s.subject == @iri.to_s
          return s.object if s.object.to_s =~ Regexp.new(id, Regexp::IGNORECASE)
        end
      end
      nil
    end

    def rdf_find_subject(id)
      # TODO: convert this to an RDF.rb graph query?
      return nil unless rdf_valid?
      rdf.each_statement do |s|
        return s.subject if s.subject.to_s =~ Regexp.new(id, Regexp::IGNORECASE)
      end
      nil
    end

    def resolve_external_auth(url)
      begin
        res = Marc2LinkedData.http_head_request(url)
        case res.code
          when 200
            @@config.logger.debug "Mapped #{@iri}\t-> #{url}"
            return url
          when 301
            #301 Moved Permanently
            url = res['location']
            @@config.logger.debug "Mapped #{@iri}\t-> #{url}"
            return url
          when 302,303
            #302 Moved Temporarily
            #303 See Other
            # Use the current URL, most get requests will follow a 302 or 303
            @@config.logger.debug "Mapped #{@iri}\t-> #{url}"
            return url
          when 404
            @@config.logger.warn "#{@iri}\t// #{url}"
            return nil
          else
            # WTF
            binding.pry if @@config.debug
            @@config.logger.error "unknown http response code (#{res.code}) for #{@iri}"
            return nil
        end
      rescue
        nil
      end
    end

    def same_as
      same_as_url = 'http://sameas.org/rdf?uri=' + URI.encode(@iri.to_s)
      RDF::Graph.load(same_as_url)
    end

    def same_as_array
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://www.w3.org/2002/07/owl#sameAs> ?o }")
      same_as.query(q).collect {|s| s[:o] }
    end

  end

end


