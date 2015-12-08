require "spec_helper"

module Marc2LinkedData

  describe Configuration do

    describe '#debug' do
      it 'default value is false' do
        ENV['DEBUG'] = nil
        config = Configuration.new
        expect(config.debug).to be_falsey
      end
    end

    describe '#debug=' do
      it 'can set value' do
        config = Configuration.new
        config.debug = true
        expect(config.debug).to be_truthy
      end
    end

    describe '#redis4marc' do
      it 'default value is false' do
        config = Configuration.new
        expect(config.redis4marc).to be_falsey
      end
    end

    describe '#redis4marc=' do
      it 'can set value' do
        config = Configuration.new
        config.redis4marc = true
        expect(config.redis4marc).to be_truthy
      end
    end

    describe '#redis_read' do
      it 'default value is false' do
        config = Configuration.new
        expect(config.redis_read).to be_falsey
      end
    end

    describe '#redis_read=' do
      it 'can set value' do
        config = Configuration.new
        config.redis_read = true
        expect(config.redis_read).to be_truthy
      end
    end

    describe '#redis_write' do
      it 'default value is false' do
        config = Configuration.new
        expect(config.redis_write).to be_falsey
      end
    end

    describe '#redis_write=' do
      it 'can set value' do
        config = Configuration.new
        config.redis_write = true
        expect(config.redis_write).to be_truthy
      end
    end

    describe '#prefixes' do
      it 'default value is a hash' do
        config = Configuration.new
        expect(config.prefixes).to be_instance_of Hash
      end
    end

    describe '#prefixes=' do
      it 'can set value to hash' do
        config = Configuration.new
        config.prefixes = {}
        expect(config.prefixes).to be_empty
      end
    end

    describe '#threads' do
      it 'default value is true' do
        config = Configuration.new
        expect(config.threads).to be true
      end
    end

    describe '#threads=' do
      it 'can set value' do
        config = Configuration.new
        config.threads = false
        expect(config.threads).to be false
      end
    end

    describe '#thread_limit' do
      it 'default value is 4' do
        config = Configuration.new
        expect(config.thread_limit).to eq(4)
      end
    end

    describe '#thread_limit=' do
      it 'can set value' do
        config = Configuration.new
        config.thread_limit = 10
        expect(config.thread_limit).to eq(10)
      end
    end

    describe '#thread_pause' do
      it 'default value is 10' do
        config = Configuration.new
        expect(config.thread_pause).to eq(10)
      end
    end

    describe '#thread_pause=' do
      it 'can set value' do
        config = Configuration.new
        config.thread_pause = 20
        expect(config.thread_pause).to eq(20)
      end
    end

  end
end
