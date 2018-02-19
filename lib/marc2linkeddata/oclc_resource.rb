require_relative 'resource'

module Marc2LinkedData

  class OclcResource < Resource

    PREFIX = 'http://www.worldcat.org/oclc/'

    def initialize(uri=nil)
      # Try to ensure the OCLC IRI will work for RDF retrieval.
      uri = uri.to_s.gsub('experiment','')
      unless uri =~ /www\./
        uri = uri.to_s.gsub('worldcat.org','www.worldcat.org')
      end
      super(uri)
    end

    def rdf
      # e.g. 'http://worldcat.org/oclc/004957186'
      # also 'http://www.worldcat.org/oclc/004957186'
      return nil if @iri.nil?
      @rdf ||= begin
        uri4rdf = @iri.to_s
        uri4rdf += '.rdf' unless uri4rdf.end_with? '.rdf'
        get_rdf(uri4rdf)
      end
    end

    def book?
      iri_type_match? RDF::Vocab::SCHEMA.Book
    end

    def creator?(uri)
      creators.include? RDF::URI.new(uri)
    end

    def contributor?(uri)
      contributors.include? RDF::URI.new(uri)
    end

    def editor?(uri)
      editors.include? RDF::URI.new(uri)
    end

    def media_object?
      iri_type_match? RDF::Vocab::SCHEMA.MediaObject
    end

    def about
      q = SPARQL.parse('SELECT * WHERE { ?s <http://schema.org/about> ?o }')
      rdf.query(q)
    end

    def creators
      q = [rdf_uri, RDF::Vocab::SCHEMA.creator, nil]
      rdf.query(q).objects.to_a
    end

    def contributors
      q = [rdf_uri, RDF::Vocab::SCHEMA.contributor, nil]
      rdf.query(q).objects.to_a
    end

    def editors
      q = [rdf_uri, RDF::Vocab::SCHEMA.editor, nil]
      rdf.query(q).objects.to_a
    end

    def publishers
      q = [rdf_uri, RDF::Vocab::SCHEMA.publisher, nil]
      rdf.query(q).objects.to_a
    end

    # @return ISBNs [Array<RDF::URI>]
    def isbns
      q = [rdf_uri, RDF::Vocab::SCHEMA.isbn, nil]
      rdf.query(q).objects.to_a
    end

  end

end

