require_relative 'resource'

module Marc2LinkedData

  class Isni < Resource

    # Interesting slide presentation about ISNI
    # http://www.slideshare.net/JaniferGatenby/viaf-and-isni-ifla-2014-0815

    PREFIX = 'http://www.isni.org/isni/'

    def rdf
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      # TODO: determine how to get RDF
      # TODO: not clear whether ISNI provides RDF (VIAF may be better)
      @rdf = RDF::Graph.load(@iri.to_s)
    end

  end

end

