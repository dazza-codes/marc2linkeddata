
module Marc2LinkedData

  class Configuration

    attr_accessor :debug
    attr_accessor :prefixes
    attr_accessor :redis4marc
    attr_accessor :redis_ro
    attr_accessor :redis_wo
    attr_accessor :redis

    def initialize
      @debug = false
      # RDF prefixes
      @prefixes = {}
      @prefixes['bf'] = 'http://bibframe.org/vocab/'
      @prefixes['foaf'] = 'http://xmlns.com/foaf/0.1/'
      @prefixes['isni'] = 'http://www.isni.org/isni/'
      @prefixes['lib'] = 'http://linked-data.stanford.edu/library/'
      @prefixes['lib_auth'] = "#{prefixes['lib']}authority/"
      @prefixes['lib_cat']  = "#{prefixes['lib']}catalog/"
      @prefixes['loc_names'] = 'http://id.loc.gov/authorities/names/'
      @prefixes['loc_subjects'] = 'http://id.loc.gov/authorities/subjects/'
      @prefixes['owl'] = 'http://www.w3.org/2002/07/owl#'
      @prefixes['viaf'] = 'http://viaf.org/viaf/'
      # persistence options
      @redis_url = ENV['REDIS_URL']
      @redis4marc = ENV['REDIS4MARC']
      @redis_ro = ENV['REDIS_RO'] || @redis4marc
      @redis_wo = ENV['REDIS_WO'] || @redis4marc
      redis_config
    end

    def redis_config
      @redis = nil
      if @redis4marc
        # https://github.com/redis/redis-rb
        # storing objects in redis:
        #redis.set "foo", [1, 2, 3].to_json
        #JSON.parse(redis.get("foo"))
        require 'hiredis'
        require 'redis'
        if @redis_url
          @redis = Redis.new(:url => @redis_url)
        else
          @redis = Redis.new # default host config
        end
        @redis.ping
      end
    end

  end

end

