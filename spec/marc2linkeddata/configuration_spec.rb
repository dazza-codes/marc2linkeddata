require "spec_helper"

module Marc2LinkedData

  describe Configuration do

    describe "#debug" do
      it "default value is false" do
        config = Configuration.new
        expect(config.debug).to be_falsey
      end
    end

    describe "#debug=" do
      it "can set value" do
        config = Configuration.new
        config.debug = true
        expect(config.debug).to be_truthy
      end
    end

    describe "#redis4marc" do
      it "default value is false" do
        config = Configuration.new
        expect(config.redis4marc).to be_falsey
      end
    end

    describe "#redis4marc=" do
      it "can set value" do
        config = Configuration.new
        config.redis4marc = true
        expect(config.redis4marc).to be_truthy
      end
    end

    describe "#redis_ro" do
      it "default value is false" do
        config = Configuration.new
        expect(config.redis_ro).to be_falsey
      end
    end

    describe "#redis_ro=" do
      it "can set value" do
        config = Configuration.new
        config.redis_ro = true
        expect(config.redis_ro).to be_truthy
      end
    end

    describe "#redis_wo" do
      it "default value is false" do
        config = Configuration.new
        expect(config.redis_wo).to be_falsey
      end
    end

    describe "#redis_wo=" do
      it "can set value" do
        config = Configuration.new
        config.redis_wo = true
        expect(config.redis_wo).to be_truthy
      end
    end

    describe "#prefixes" do
      it "default value is a hash" do
        config = Configuration.new
        expect(config.prefixes).to be_instance_of Hash
      end
    end

    describe "#prefixes=" do
      it "can set value to hash" do
        config = Configuration.new
        config.prefixes = {}
        expect(config.prefixes).to be_empty
      end
    end
  end
end
