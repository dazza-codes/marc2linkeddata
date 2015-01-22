require_relative 'resource'

module Marc2LinkedData

  class OclcWork < Resource

    # OCLC is inconsistent with use of 'www' in URIs
    #PREFIX = 'http://www.worldcat.org/entity/work/id/'
    PREFIX = 'http://worldcat.org/entity/work/id/'

    def rdf
      # e.g. 'http://worldcat.org/oclc/004957186'
      return nil if iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = iri.to_s
      uri4rdf += '.rdf' unless uri4rdf.end_with? '.rdf'
      @rdf = get_rdf(uri4rdf)
    end

    def get_creators
      rdf.query(query_creators).collect {|s| s[:o] }
    end

    def query_creators
      SPARQL.parse("SELECT * WHERE { <#{query_uri}> <http://schema.org/contributor> ?o }")
    end

    def get_contributors
      rdf.query(query_contributors).collect {|s| s[:o] }
    end

    def query_contributors
      SPARQL.parse("SELECT * WHERE { <#{query_uri}> <http://schema.org/contributor> ?o }")
    end

    def get_examples
      rdf.query(query_examples).collect {|s| s[:o] }
    end

    def query_examples
      SPARQL.parse("SELECT * WHERE { <#{query_uri}> <http://schema.org/workExample> ?o }")
    end

    def query_uri
      # Ensure we always use the full URI prefix in SPARQL
      PREFIX + id
    end

  end

end

