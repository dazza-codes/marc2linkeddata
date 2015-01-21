
module Marc2LinkedData

  class Configuration

    attr_accessor :debug
    attr_accessor :prefixes
    attr_accessor :redis4marc
    attr_accessor :redis_read
    attr_accessor :redis_write
    attr_accessor :redis

    attr_reader :logger

    def initialize
      @debug = ENV['DEBUG'].upcase == 'TRUE' rescue false

      log_file = ENV['LOG_FILE'] || 'marc2ld.log'
      @logger = Logger.new File.new(log_file, 'w+')
      @logger.level = @debug ? Logger::DEBUG : Logger::INFO

      # RDF prefixes
      @prefixes = {}
      # Library specific prefixes (use .env file or set shell ENV)
      @prefixes['lib'] = ENV['LIB_PREFIX'] || 'http://linked-data.stanford.edu/library/'
      @prefixes['lib_auth'] = "#{prefixes['lib']}authority/"
      @prefixes['lib_cat']  = "#{prefixes['lib']}catalog/"
      # Static Prefixes
      @prefixes['bf'] = 'http://bibframe.org/vocab/'
      @prefixes['foaf'] = 'http://xmlns.com/foaf/0.1/'
      @prefixes['isni'] = 'http://www.isni.org/isni/'
      @prefixes['loc_names'] = 'http://id.loc.gov/authorities/names/'
      @prefixes['loc_subjects'] = 'http://id.loc.gov/authorities/subjects/'
      @prefixes['owl'] = 'http://www.w3.org/2002/07/owl#'
      @prefixes['viaf'] = 'http://viaf.org/viaf/'

      # Persistence options
      @redis = nil
      @redis4marc = ENV['REDIS4MARC'].upcase == 'TRUE' rescue false
      if @redis4marc
        @redis_url = ENV['REDIS_URL']
        @redis_read  = ENV['REDIS_READ'].upcase == 'TRUE' rescue true
        @redis_write = ENV['REDIS_WRITE'].upcase == 'TRUE' rescue true
        redis_config
      else
        @redis_url = nil
        @redis_read  = false
        @redis_write = false
      end
      # TODO: provide options for triple stores
    end

    def redis_config
      if @redis4marc
        # https://github.com/redis/redis-rb
        # storing objects in redis:
        #redis.set "foo", [1, 2, 3].to_json
        #JSON.parse(redis.get("foo"))
        require 'hiredis'
        require 'redis'
        if @redis_url
          # redis url should be of the form "redis://{user}:{password}@{host}:{port}/{db}"
          @redis = Redis.new(:url => @redis_url)
          @redis.ping
        else
          # default is 'redis://127.0.0.1:6379/0'
          @redis = Redis.new
          @redis.ping
        end
      end
    end

  end

end

