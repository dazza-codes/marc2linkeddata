require 'spec_helper'

describe Marc2LinkedData do

  describe "#configure" do
    before :each do
      Marc2LinkedData.configure do |config|
        config.debug = true
      end
    end
    it "returns a hash of options" do
      config = Marc2LinkedData.configuration
      expect(config).to be_instance_of Marc2LinkedData::Configuration
      expect(config.debug).to be_truthy
    end
    after :each do
      Marc2LinkedData.reset
    end
  end

  describe ".reset" do
    before :each do
      Marc2LinkedData.configure do |config|
        config.debug = true
      end
    end
    it "resets the configuration" do
      Marc2LinkedData.reset
      config = Marc2LinkedData.configuration
      expect(config).to be_instance_of Marc2LinkedData::Configuration
      expect(config.debug).to be_falsey
    end
    after :each do
      Marc2LinkedData.reset
    end
  end

end

