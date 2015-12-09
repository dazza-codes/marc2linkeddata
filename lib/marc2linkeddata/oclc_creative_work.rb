require_relative 'oclc_resource'

module Marc2LinkedData

  class OclcCreativeWork < OclcResource

    PREFIX = 'http://www.worldcat.org/oclc/'

    # @return fast [Array<RDF::URI>]
    # @example:
    #   [
    #     #<RDF::URI:0x3fc7c46a0c68 URI:http://id.worldcat.org/fast/999098>,
    #     #<RDF::URI:0x3fc7c4a025a0 URI:http://id.worldcat.org/fast/1141385>,
    #     #<RDF::URI:0x3fc7c4a1b014 URI:http://id.worldcat.org/fast/1131964>
    #   ]
    def fast
      @fast ||= begin
        fast_uri = 'http://id.worldcat.org/fast/'
        q = [rdf_uri, RDF::Vocab::SCHEMA.about, nil]
        rdf.query(q).objects.select {|o| o.to_s.include?(fast_uri) }
      end
    end

    # @return isbn [Array<RDF::URI>]
    # @example:
    #   [#<RDF::URI:0x3fc7c49f4e3c URI:http://worldcat.org/isbn/9780444700384>]
    def isbn
      q = [rdf_uri, RDF::Vocab::SCHEMA.workExample, nil]
      rdf.query(q).objects.select {|o| o.to_s.include?('isbn') }
    end

    # @return name [String]
    def name
      @name ||= begin
        q = [rdf_uri, RDF::Vocab::SCHEMA.name, nil]
        rdf.query(q).map {|s| s.object.to_s }.first
      end
    end

    def get_works
      q = query_work(@iri)
      works = rdf.query(q).map {|s| s[:o] }
      if works.empty?
        # OCLC data is inconsistent in use of 'www.' in IRI, so try again.
        # The OclcResource coerces @iri so it includes 'www.', so try without it.
        uri = @iri.to_s.gsub('www.','')
        q = query_work(uri)
        works = rdf.query(q).map {|s| s[:o] }
      end
      if works.empty?
        # Keep the 'www.', cast the ID to an integer.
        uri = @iri.to_s.gsub(id, id.to_i.to_s)
        q = query_work(uri)
        works = rdf.query(q).map {|s| s[:o] }
      end
      if works.empty?
        # Remove the 'www.' AND cast the ID to an integer.
        uri = @iri.to_s.gsub('www.','').gsub(id, id.to_i.to_s)
        q = query_work(uri)
        works = rdf.query(q).map {|s| s[:o] }
      end
      works
    end

    def query_work(uri)
      SPARQL.parse("SELECT * WHERE { <#{uri}> <http://schema.org/exampleOfWork> ?o }")
    end

    # TODO: get ISBN?

  end

end

