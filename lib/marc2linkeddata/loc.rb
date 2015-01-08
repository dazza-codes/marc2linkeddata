require_relative 'auth'

module Marc2LinkedData

  class Loc < Auth

    PREFIX = 'http://id.loc.gov/authorities/'
    PREFIX_NAMES = "#{PREFIX}names/"
    PREFIX_SUBJECTS = "#{PREFIX}subjects/"

    # def id
    #   return nil if @iri.nil?
    #   @id ||= @iri.basename
    #   # Could get id from rdf, but that incurs costs for RDF retrieval and parsing etc.
    #   #oclc_id = '<identifiers:oclcnum>oca04921729</identifiers:oclcnum>'
    #   #<identifiers:lccn>no 99010609</identifiers:lccn>
    #   #<identifiers:oclcnum>oca04921729</identifiers:oclcnum>
    # end

    def rdf
      return nil if @iri.nil?
      uri4rdf = @iri.to_s + '.rdf'
      @rdf ||= RDF::Graph.load(uri4rdf)
    end

    def label
      label_predicate = '<http://www.loc.gov/mads/rdf/v1#authoritativeLabel>'
      query = SPARQL.parse("SELECT * WHERE { <#{@iri}> #{label_predicate} ?o }")
      rdf.query(query).first[:o].to_s rescue nil
    end

    def authority?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#Authority' }.length > 0
    end

    def deprecated?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#DeprecatedAuthority' }.length > 0
    end

    def conference?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#ConferenceName' }.length > 0
    end

    def corporation?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#CorporateName' }.length > 0
    end

    def name_title?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#NameTitle' }.length > 0
    end

    def person?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#PersonalName' }.length > 0
      # iri_types.filter {|s| s[:o] =~ /PersonalName/ }.length > 0
      # obj = rdf_find_object 'PersonalName'
      # obj.nil? ? false : true
    end

    def place?
      iri_types.filter {|s| s[:o] == 'http://www.loc.gov/mads/rdf/v1#Geographic' }.length > 0
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

