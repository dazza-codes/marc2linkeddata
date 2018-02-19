require_relative 'resource'

module Marc2LinkedData

  class Loc < Resource

    PREFIX = 'http://id.loc.gov/authorities/'
    PREFIX_NAMES = "#{PREFIX}names/"
    PREFIX_SUBJECTS = "#{PREFIX}subjects/"

    def rdf
      return nil if @iri.nil?
      @rdf ||= begin
        uri4rdf = @iri.to_s + '.rdf'
        get_rdf(uri4rdf)
      end
    end

    def label
      q = [rdf_uri, RDF::Vocab::MADS.authoritativeLabel, nil]
      rdf.query(q).objects.first
    end

    def authority?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#Authority'
    end

    def deprecated?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#DeprecatedAuthority'
    end

    def conference?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#ConferenceName'
    end

    def corporation?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#CorporateName'
    end

    def name_title?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#NameTitle'
    end

    def person?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#PersonalName'
    end

    def geographic?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#Geographic'
    end

    def uniform_title?
      iri_type_match? 'http://www.loc.gov/mads/rdf/v1#Title'
    end

    def get_oclc_identity
      # Try to get OCLC URI from LOC ID
      # http://oclc.org/developer/develop/web-services/worldcat-identities.en.html
      # e.g. http://www.worldcat.org/identities/lccn-n79044803/
      # e.g. http://www.worldcat.org/identities/lccn-n79044798/
      return @oclc_iri unless @oclc_iri.nil?
      oclc_url = URI.encode('http://www.worldcat.org/identities/lccn-' + id + '/')
      @oclc_iri = resolve_external_auth(oclc_url)
      # TODO: OCLC might redirect and then provide a 'fast' URI for obsolete identity records.
    end

    def get_viaf
      return @viaf_iri unless @viaf_iri.nil?
      # Try to get VIAF from LOC sourceID
      # LOC statement with VIAF URI, e.g.:
      # s: <http://id.loc.gov/authorities/names/n79046291>
      # p: <http://www.loc.gov/mads/rdf/v1#hasExactExternalAuthority>
      # o: <http://viaf.org/viaf/sourceID/LC%7Cn+79046291#skos:Concept> .
      #return nil unless rdf_valid?
      #@viaf_iri ||= rdf_find_object 'viaf'
      viaf_url = URI.encode('http://viaf.org/viaf/sourceID/LC|' + id + '#skos:Concept')
      @viaf_iri = resolve_external_auth(viaf_url)
    end

  end

end

