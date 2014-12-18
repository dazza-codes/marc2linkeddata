require "spec_helper"

module Marc2LinkedData

  describe Auth do

    before :all do
      @auth_url = 'http://id.loc.gov/authorities/names/no99010609'
      # @auth = Auth.new @auth_url
    end

    describe "#initialize" do
      it "should not raise error for a valid iri" do
        iri_valid = 'http://id.loc.gov/authorities/names/no99010609'
        expect{Loc.new @auth_url}.not_to raise_error
      end
      it "should raise error for an invalid iri" do
        expect{Loc.new 'This is not a URL'}.to raise_error(RuntimeError)
      end
    end

    after :all do
      @auth_url = nil
      @auth = nil
    end

  end

end


