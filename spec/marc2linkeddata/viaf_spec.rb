require "spec_helper"

module Marc2LinkedData

  describe Viaf do

    before :all do
      # valid data (Knuth, Donald Ervin)
      @viaf_id = '7466303'
      @viaf_url = 'http://viaf.org/viaf/7466303'
      @isni_url = 'http://www.isni.org/isni/000000012119421X'
      @viaf = Viaf.new @viaf_url
    end

    before :each do
    end

    describe "#id" do
      it "should equal the viaf url basename" do
        expect(@viaf.id).to eq(@viaf_id)
      end
    end

    #     viaf = Marc2LinkedData::Viaf.new iri
    #     raise "Invalid ID" unless viaf.id == '7466303'
    #     raise "Failed to get RDF" if viaf.rdf.nil?
    #     raise "Invalid RDF" unless viaf.rdf_valid? rescue binding.pry
    #     raise "Failed to get ISNI" if viaf.get_isni != isni_iri
    #     raise "Failed to get sameAs" if viaf.same_as_array.empty?

    after :each do
    end

    after :all do
      @viaf_id = nil
      @viaf_url = nil
      @isni_url = nil
      @viaf = nil
    end
  end
end

