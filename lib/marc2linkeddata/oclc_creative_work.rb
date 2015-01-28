require_relative 'oclc_resource'

module Marc2LinkedData

  class OclcCreativeWork < OclcResource

    PREFIX = 'http://www.worldcat.org/oclc/'

    def get_works
      # assume an exampleOfWork can only ever link to one work?
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://schema.org/exampleOfWork> ?o }")
      works = rdf.query(q).collect {|s| s[:o] }
      if works.empty?
        # OCLC data is inconsistent in use of 'www' in IRI, so try again?
        # The OclcResource coerces @iri so it includes 'www', so try without it.
        uri = @iri.to_s.gsub('www.','')
        q = SPARQL.parse("SELECT * WHERE { <#{uri}> <http://schema.org/exampleOfWork> ?o }")
        works = rdf.query(q).collect {|s| s[:o] }
      end
      if works.empty?
        # OCLC IRIs use inconsistent identifiers, sometimes the ID is an integer.
        uri = iri.to_s.gsub(id, id.to_i.to_s)
        q = SPARQL.parse("SELECT * WHERE { <#{uri}> <http://schema.org/exampleOfWork> ?o }")
        works = rdf.query(q).collect {|s| s[:o] }
      end

      works
    end

    # TODO: get ISBN?

  end

end

