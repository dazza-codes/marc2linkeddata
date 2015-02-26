require_relative 'resource'

module Marc2LinkedData

  class BNF < Resource

    # http://data.bnf.fr/
    # http://data.bnf.fr/docs/doc_requetes_data_en.pdf
    # BNF links to digital content in 'Gallica' with ISBN URIs for digitized books.

    #<RDF::URI:0x3fa83a561194 URI:http://data.bnf.fr/ark:/12148/cb12358391w>
    # eg. http://data.bnf.fr/12358391/donald_ervin_knuth/
    # RDF: http://data.bnf.fr/12358391/donald_ervin_knuth/rdf.xml
    # linked to ISNI: http://isni-url.oclc.nl/isni/000000012119421X
    # linked to VIAF: http://viaf.org/viaf/7466303

    @@client = SPARQL::Client.new('http://data.bnf.fr/sparql')

    def rdf
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = @iri.to_s + '/rdf.xml'
      @rdf = get_rdf(uri4rdf)
    end

    def exactMatch
      # e.g.
      # <skos:exactMatch rdf:resource="http://fr.wikipedia.org/wiki/Donald_Knuth"/>
      # <skos:exactMatch rdf:resource="http://isni-url.oclc.nl/isni/000000012119421X"/>
      # <skos:exactMatch rdf:resource="http://viaf.org/viaf/7466303"/>
      # <skos:exactMatch rdf:resource="http://www.idref.fr/032581270"/>
      # <skos:exactMatch rdf:resource="http://dbpedia.org/resource/Donald_Knuth"/>
      begin
        select = "select * where { <#{rdf_uri}> <#{RDF::SKOS.exactMatch}> ?o . }"
        solutions = @@client.query(select)
        solutions.collect {|s| s[:o].to_s}
      rescue => e
        Marc2LinkedData::Utils.stack_trace(e)
        binding.pry if @@config.debug
        nil
      end

    end

  end

end

