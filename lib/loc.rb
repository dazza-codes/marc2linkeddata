require_relative 'auth'

class Loc < Auth

  PREFIX = 'http://id.loc.gov/authorities/'
  PREFIX_NAMES = "#{PREFIX}names/"
  PREFIX_SUBJECTS = "#{PREFIX}subjects/"

  def id
    return nil if @iri.nil?
    @id ||= @iri.path.gsub('/authorities/names/','').gsub('/authorities/subjects/','')
  end

  def rdf
    return nil if @iri.nil?
    uri4rdf = @iri.to_s + '.rdf'
    @rdf ||= RDF::Graph.load(uri4rdf)
  end

  def deprecated?
    obj = rdf_find_object 'DeprecatedAuthority'
    obj.nil? ? false : true
  end

  def corporation?
    # <http://www.loc.gov/mads/rdf/v1#CorporateName>
    obj = rdf_find_object 'CorporateName'
    obj.nil? ? false : true
  end

  def person?
    # <http://www.loc.gov/mads/rdf/v1#PersonalName>
    obj = rdf_find_object 'PersonalName'
    obj.nil? ? false : true
  end

  def get_viaf
    return nil if @iri.nil?
    return nil unless rdf_valid?
    # Try to get VIAF from LOC sourceID
    # LOC statement with VIAF URI, e.g.:
    # s: <http://id.loc.gov/authorities/names/n79046291>
    # p: <http://www.loc.gov/mads/rdf/v1#hasExactExternalAuthority>
    # o: <http://viaf.org/viaf/sourceID/LC%7Cn+79046291#skos:Concept> .
    @viaf_iri ||= rdf_find_object 'viaf'
    @viaf_iri = resolve_external_auth(@viaf_iri.to_s)
  end

end


if __FILE__ == $0
  # valid data (Knuth, Donald Ervin)
  loc_iris = ['http://id.loc.gov/authorities/names/n79135509', 'http://id.loc.gov/authorities/names/n79135509/']
  viaf_iri = 'http://viaf.org/viaf/7466303/'
  loc_iris.each do |iri|
    loc =  Loc.new iri
    raise "Invalid ID" unless loc.id == 'n79135509'
    raise "Failed to get RDF" if loc.rdf.nil?
    raise "Invalid RDF" unless loc.rdf_valid?
    # TODO: Enable this when LOC data is fixed?
    #raise "Failed to get VIAF" if loc.get_viaf != viaf_iri
  end
  # invalid data
  loc =  Loc.new 'This is not an LOC IRI'
  raise "ID method doesn't fail gracefully" unless loc.id.nil?
  raise "RDF method doesn't fail gracefully" unless loc.rdf.nil?
  raise "RDF validation error" if loc.rdf_valid?
end

