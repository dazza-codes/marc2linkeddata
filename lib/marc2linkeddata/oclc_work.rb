require_relative 'oclc_resource'

module Marc2LinkedData

  class OclcWork < OclcResource

    # OCLC is inconsistent with use of 'www' in URIs
    #PREFIX = 'http://www.worldcat.org/entity/work/id/'
    PREFIX = 'http://worldcat.org/entity/work/id/'

    def get_examples
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://schema.org/workExample> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end

  end

end

