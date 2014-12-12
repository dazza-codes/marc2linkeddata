require_relative 'auth'

class Viaf < Auth

  PREFIX = 'http://viaf.org/viaf/'

  def id
    return nil if @iri.nil?
    @id ||= @iri.path.gsub('viaf/','').gsub('/','')
  end

  def rdf
    return nil if @iri.nil?
    uri4rdf = @iri.to_s + '/rdf.xml'
    @rdf ||= RDF::Graph.load(uri4rdf)
  end

  def get_isni
    return nil if @iri.nil?
    return nil unless rdf_valid?
    # Try to get ISNI source for VIAF
    # e.g. http://viaf.org/viaf/sourceID/ISNI%7C0000000109311081#skos:Concept
    @isni_iri ||= rdf_find_subject 'isni'
    return nil if @isni_iri.nil?
    isni_src = URI.parse(@isni_iri.to_s)
    @isni_iri = isni_src.path.sub('/viaf/sourceID/ISNI%7C','http://www.isni.org/isni/')
    @isni_iri = resolve_external_auth(@isni_iri)
  end

end


if __FILE__ == $0
  # valid data (Knuth, Donald Ervin)
  viaf_iris = ['http://viaf.org/viaf/7466303/', 'http://viaf.org/viaf/7466303']
  isni_iri = 'http://www.isni.org/isni/000000012119421X'
  viaf_iris.each do |iri|
    viaf =  Viaf.new iri
    raise "Invalid ID" unless viaf.id == '7466303'
    raise "Failed to get RDF" if viaf.rdf.nil?
    raise "Invalid RDF" unless viaf.rdf_valid?
    raise "Failed to get ISNI" if viaf.get_isni != isni_iri
  end
  # invalid data
  viaf =  Viaf.new 'This is not a VIAF IRI'
  raise "ID method doesn't fail gracefully" unless viaf.id.nil?
  raise "RDF method doesn't fail gracefully" unless viaf.rdf.nil?
  raise "ISNI method doesn't fail gracefully" unless viaf.get_isni.nil?
end

