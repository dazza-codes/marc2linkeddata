require_relative 'resource'

module Marc2LinkedData

  class Viaf < Resource

    PREFIX = 'http://viaf.org/viaf/'

    # def id
    #   return nil if @iri.nil?
    #   iri.path.gsub('viaf/','').gsub('/','')
    # end

    def rdf
      return nil if @iri.nil?
      return @rdf unless @rdf.nil?
      uri4rdf = @iri.to_s + '/rdf.xml'
      @rdf = get_rdf(uri4rdf)
    end

    def get_isni
      return nil if @iri.nil?
      return nil unless rdf_valid?
      return @isni_iri unless @isni_iri.nil?
      # Try to get ISNI source for VIAF
      # e.g. http://viaf.org/viaf/sourceID/ISNI%7C0000000109311081#skos:Concept
      isni_iri = rdf_find_subject 'isni'
      isni_src = URI.parse(isni_iri.to_s)
      isni_iri = isni_src.path.sub('/viaf/sourceID/ISNI%7C','http://www.isni.org/isni/')
      @isni_iri = resolve_external_auth(isni_iri)
    end

    def given_names
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://schema.org/givenName> ?o }")
      names = rdf.query(q).collect {|s| s[:o].to_s}
      names.to_set.to_a
    end

    def family_names
      q = SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://schema.org/familyName> ?o }")
      names = rdf.query(q).collect {|s| s[:o].to_s}
      names.to_set.to_a
    end

  end

end

