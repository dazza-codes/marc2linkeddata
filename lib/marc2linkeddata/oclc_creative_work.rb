require_relative 'resource'

module Marc2LinkedData

  class OclcCreativeWork < Resource

    PREFIX = 'http://www.worldcat.org/oclc/'

    def rdf
      # e.g. 'http://worldcat.org/oclc/004957186'
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = @iri.to_s
      uri4rdf += '.rdf' unless uri4rdf.end_with? '.rdf'
      @rdf = RDF::Graph.load(uri4rdf)
    end

    def get_work
      works = rdf.query(query_work).collect {|s| s[:oclcWork] }
      works.first.to_s
    end

    def query_work
      SPARQL.parse("SELECT * WHERE { <#{query_uri}> <http://schema.org/exampleOfWork> ?oclcWork }")
    end

    def query_uri
      # Ensure we always use the full URI prefix in SPARQL
      PREFIX + id
    end

  end

end

