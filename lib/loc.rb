require_relative 'auth'

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

  def authority?
    @authority ||= iri_types.filter {|s| s[:o] == "http://www.loc.gov/mads/rdf/v1#Authority" }.length > 0
  end

  def deprecated?
    @deprecated ||= iri_types.filter {|s| s[:o] == "http://www.loc.gov/mads/rdf/v1#DeprecatedAuthority" }.length > 0
  end

  def corporation?
    @corporation ||= iri_types.filter {|s| s[:o] == "http://www.loc.gov/mads/rdf/v1#CorporateName" }.length > 0
    # iri_types.filter {|s| s[:o] =~ /CorporateName/ }.length > 0
    # obj = rdf_find_object 'CorporateName'
    # obj.nil? ? false : true
  end

  def person?
    @person ||= iri_types.filter {|s| s[:o] == "http://www.loc.gov/mads/rdf/v1#PersonalName" }.length > 0
    # <http://www.loc.gov/mads/rdf/v1#PersonalName>
    # iri_types.filter {|s| s[:o] =~ /PersonalName/ }.length > 0
    # obj = rdf_find_object 'PersonalName'
    # obj.nil? ? false : true
  end

  def get_viaf
    return nil if @iri.nil?
    return nil unless rdf_valid?
    # Try to get VIAF from LOC sourceID
    # LOC statement with VIAF URI, e.g.:
    # s: <http://id.loc.gov/authorities/names/n79046291>
    # p: <http://www.loc.gov/mads/rdf/v1#hasExactExternalAuthority>
    # o: <http://viaf.org/viaf/sourceID/LC%7Cn+79046291#skos:Concept> .
    #@viaf_iri ||= rdf_find_object 'viaf'
    @viaf_iri ||= URI.encode('http://viaf.org/viaf/sourceID/LC|' + id + '#skos:Concept')
    @viaf_iri = resolve_external_auth(@viaf_iri.to_s)
  end

end


if __FILE__ == $0
  # valid data (Berners-Lee, Tim)
  loc_iris = ['http://id.loc.gov/authorities/names/no99010609', 'http://id.loc.gov/authorities/names/no99010609/']
  viaf_iri = 'http://viaf.org/viaf/85312226'
  # valid data (Knuth, Donald Ervin)
  # loc_iris = ['http://id.loc.gov/authorities/names/n79135509', 'http://id.loc.gov/authorities/names/n79135509/']
  # viaf_iri = 'http://viaf.org/viaf/7466303'
  loc_iris.each do |iri|
    id = Addressable::URI.parse(iri).basename
    loc =  Loc.new iri
    raise "Invalid ID" unless loc.id == id
    raise "Failed to get RDF" if loc.rdf.nil?
    raise "Invalid RDF" unless loc.rdf_valid?
    raise "Failed to get VIAF" if loc.get_viaf != viaf_iri
    raise "Failed to get sameAs" if loc.same_as_array.empty?
  end
  # invalid data
  loc =  Loc.new 'This is not an LOC IRI'
  raise "ID method doesn't fail gracefully" unless loc.id.nil?
  raise "RDF method doesn't fail gracefully" unless loc.rdf.nil?
  raise "RDF validation error" if loc.rdf_valid?
end

