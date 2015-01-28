require_relative 'resource'

module Marc2LinkedData

  class OclcResource < Resource

    PREFIX = 'http://www.worldcat.org/oclc/'

    def initialize(uri=nil)
      # Ensure the OCLC IRI contains 'www' in the host name.
      uri = uri.to_s.gsub('worldcat.org','www.worldcat.org').gsub('wwwwww','')
      super(uri)
    end

    def rdf
      # e.g. 'http://worldcat.org/oclc/004957186'
      # also 'http://www.worldcat.org/oclc/004957186'
      return nil if iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = iri.to_s
      uri4rdf += '.rdf' unless uri4rdf.end_with? '.rdf'
      @rdf = get_rdf(uri4rdf)
    end

    def book?
      iri_types.filter {|s| s[:o] == 'http://schema.org/Book' }.length > 0
    end

    def creator?(uri)
      uri = RDF::URI.new uri
      creators.include? uri
    end

    def contributor?(uri)
      uri = RDF::URI.new uri
      contributors.include? uri
    end

    def editor?(uri)
      uri = RDF::URI.new uri
      editors.include? uri
    end

    def media_object?
      iri_types.filter {|s| s[:o] == 'http://schema.org/MediaObject' }.length > 0
    end

    def about
      q = SPARQL.parse('SELECT * WHERE { ?s <http://schema.org/about> ?o }')
      rdf.query(q)
    end

    def creators
      q = SPARQL.parse("SELECT * WHERE { <#{@iri.to_s}> <http://schema.org/creator> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end

    def contributors
      q = SPARQL.parse("SELECT * WHERE { <#{@iri.to_s}> <http://schema.org/contributor> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end

    def editors
      q = SPARQL.parse("SELECT * WHERE { <#{@iri.to_s}> <http://schema.org/editor> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end

    def publishers
      q = SPARQL.parse("SELECT * WHERE { <#{@iri.to_s}> <http://schema.org/publishers> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end

    def isbns
      q = SPARQL.parse("SELECT * WHERE { <#{@iri.to_s}> <http://schema.org/isbn> ?o }")
      rdf.query(q).collect {|s| s[:o] }
    end
  end

end

