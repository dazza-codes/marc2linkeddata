require_relative 'resource'

module Marc2LinkedData

  class Isni < Resource

    # Interesting slide presentation about ISNI
    # http://www.slideshare.net/JaniferGatenby/viaf-and-isni-ifla-2014-0815

    PREFIX = 'http://www.isni.org/isni/'

    def rdf
      # e.g. 'http://www.isni.org/isni/0000000109311081'
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = @iri.to_s + '.rdf'
      @rdf = get_rdf(uri4rdf)
    end

    def get_bnf
      #TODO: get an identifier from data.bnf.fr
      #TODO: use http://data.bnf.fr/sparql
      #TODO: review http://data.bnf.fr/docs/doc_requetes_data_en.pdf
      #<RDF::URI:0x3fa83a561194 URI:http://data.bnf.fr/ark:/12148/cb12358391w>
      # eg. http://data.bnf.fr/12358391/donald_ervin_knuth/
      # RDF: http://data.bnf.fr/12358391/donald_ervin_knuth/rdf.xml
      # linked to ISNI: http://isni-url.oclc.nl/isni/000000012119421X
      # linked to VIAF: http://viaf.org/viaf/7466303

      return @bnf unless @bnf.nil?
      begin
        select = "select distinct * where { ?s <#{RDF::SKOS.exactMatch}> <#{rdf_uri}> . }"
        client = SPARQL::Client.new('http://data.bnf.fr/sparql')
        solutions = client.query(select)
        bnf_uri = solutions.collect {|s| s[:s]}.first.to_s
        @bnf = resolve_external_auth(bnf_uri)

        # check for redirection or modify SPARQL...
        # select distinct ?s ?page where {
        # ?s skos:exactMatch <http://isni-url.oclc.nl/isni/000000012119421X> .
        #     ?s foaf:page ?page .
        # }

        # BNF links to digital content in 'Gallica' with ISBN URIs for digitized books.

      rescue => e
        binding.pry
        nil
      end

    end

  end

end

