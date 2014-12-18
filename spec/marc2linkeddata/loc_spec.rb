require "spec_helper"

module Marc2LinkedData

  describe Loc do

    before :all do
      # loc_iris = ['http://id.loc.gov/authorities/names/no99010609', 'http://id.loc.gov/authorities/names/no99010609/']
      # viaf_iri = 'http://viaf.org/viaf/85312226'
      @loc_id = 'no99010609'
      @loc_url = 'http://id.loc.gov/authorities/names/no99010609'
      @loc = Loc.new @loc_url
    end

    before :each do
    end

    describe "#id" do
      it "should equal the loc url basename" do
        expect(@loc.id).to eq(@loc_id)
      end
    end

#   raise "Failed to get RDF" if loc.rdf.nil?
#   raise "Invalid RDF" unless loc.rdf_valid?
#   raise "Failed to get VIAF" if loc.get_viaf != viaf_iri
#   raise "Failed to get sameAs" if loc.same_as_array.empty?

    after :each do
    end

    after :all do
      @loc_id = nil
      @loc_url = nil
      @loc = nil
    end
  end
end


# # valid data (Berners-Lee, Tim)
# loc_iris = ['http://id.loc.gov/authorities/names/no99010609', 'http://id.loc.gov/authorities/names/no99010609/']
# viaf_iri = 'http://viaf.org/viaf/85312226'
# # valid data (Knuth, Donald Ervin)
# # loc_iris = ['http://id.loc.gov/authorities/names/n79135509', 'http://id.loc.gov/authorities/names/n79135509/']
# # viaf_iri = 'http://viaf.org/viaf/7466303'
# loc_iris.each do |iri|
#   id = Addressable::URI.parse(iri).basename
#   loc = Marc2LinkedData::Loc.new iri
# end
# # invalid data
# loc = Marc2LinkedData.Loc.new 'This is not an LOC IRI' rescue nil
# raise "Loc.initialize failed to raise error." unless loc.nil?
