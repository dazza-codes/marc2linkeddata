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

  end

end

