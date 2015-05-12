require "spec_helper"

module Marc2LinkedData

  describe Loc, :vcr do

    before :all do
      # loc_urls = ['http://id.loc.gov/authorities/names/no99010609', 'http://id.loc.gov/authorities/names/no99010609/']
      @loc_id = 'no99010609'
      @loc_url = 'http://id.loc.gov/authorities/names/no99010609'
      @loc = Loc.new @loc_url
      @viaf_url = 'http://viaf.org/viaf/85312226/'
    end

    before :each do
    end

    describe '#rdf' do
      it 'should be an instance of RDF::Graph' do
        expect(@loc.rdf.instance_of? RDF::Graph).to be_truthy
      end
    end

    describe '#rdf_valid?' do
      it 'should be true' do
        expect(@loc.rdf_valid?).to be_truthy
      end
    end

    describe '#same_as_array' do
      it 'should be populated' do
        expect(@loc.same_as_array.empty?).to be_falsey
      end
    end

    describe '#get_viaf' do
      it 'should equal the viaf url' do
        expect(@loc.get_viaf).to eq(@viaf_url)
      end
    end

    # TODO: add tests for different types of records, e.g.
    # authorities:
    #   person, organisation, conference, etc.


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
