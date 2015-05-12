require "spec_helper"

module Marc2LinkedData

  describe Resource, :vcr do

    before :all do
      @auth_id = 'no99010609'
      @auth_url = 'http://id.loc.gov/authorities/names/no99010609'
      @auth = Resource.new @auth_url
    end

    before :each do
    end

    describe '#initialize' do
      it 'should not raise error for a valid iri' do
        # iri_valid = 'http://id.loc.gov/authorities/names/no99010609'
        expect{Resource.new @auth_url}.not_to raise_error
      end
      it 'should raise error for an invalid iri' do
        expect{Resource.new 'This is not a URL'}.to raise_error(RuntimeError)
      end
    end

    describe '#id' do
      it 'should equal the url basename' do
        expect(@auth.id).to eq(@auth_id)
      end
    end

    describe '#iri' do
      it 'should equal the auth url' do
        expect(@auth.iri.to_s).to eq(@auth_url)
      end
      it 'should be an instance of Addressable::URI' do
        expect(@auth.iri.instance_of? Addressable::URI).to be_truthy
      end
    end

    after :each do
    end

    after :all do
      @auth_url = nil
      @auth = nil
    end

  end

end


