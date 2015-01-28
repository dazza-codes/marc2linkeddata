require_relative 'resource'

module Marc2LinkedData

  class OclcIdentity < Resource

    PREFIX = 'http://www.worldcat.org/identities/'

    def rdf
      # e.g. 'http://www.worldcat.org/identities/lccn-n79044803/'
      # the html returned contains RDFa data
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = @iri.to_s
      uri4rdf += '/' unless uri4rdf.end_with? '/'
      @rdf = get_rdf(uri4rdf)
    end

    # def get_xml
    #   begin
    #     return @xml unless @xml.nil?
    #     http = Net::HTTP.new @iri.host
    #     resp = http.get(@iri.path, {'Accept' => 'application/xml'})
    #     case resp.code
    #       when '301','302','303'
    #         #301 Moved Permanently; 302 Moved Temporarily; 303 See Other
    #         resp = http.get(resp['location'], {'Accept' => 'application/xml'})
    #     end
    #     if resp.code != '200'
    #       raise
    #     end
    #     @xml = resp.body
    #   rescue
    #     puts 'ERROR: Failed to request OCLC identity xml.'
    #   end
    # end

    def creative_works
      q = SPARQL.parse('SELECT * WHERE { ?oclcWork a <http://schema.org/CreativeWork> }')
      rdf.query(q).collect {|s| s[:oclcWork] }
    end

  end

end

