require 'spec_helper'

module Marc2LinkedData

  describe Viaf, :vcr do

    before :all do
      # valid data (Knuth, Donald Ervin)
      @viaf_id = '7466303'
      @viaf_url = 'http://viaf.org/viaf/7466303'
      @viaf = Viaf.new @viaf_url
      @isni_url = 'http://www.isni.org/isni/000000012119421X'
    end

    before :each do
    end

    describe '#rdf' do
      it 'should be an instance of RDF::Graph' do
        expect(@viaf.rdf).to be_instance_of RDF::Graph
      end
    end

    describe '#rdf_valid?' do
      it 'should be true' do
        expect(@viaf.rdf_valid?).to be true
      end
    end

    describe '#search_sameAs' do
      it 'should be populated' do
        expect(@viaf.search_sameAs).not_to be_empty
      end
    end

    describe '#get_isni' do
      it 'should equal the isni url' do
        expect(@viaf.get_isni).to eq(@isni_url)
      end
    end

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

