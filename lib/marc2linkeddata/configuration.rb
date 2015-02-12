
module Marc2LinkedData

  class Configuration

    attr_accessor :debug

    attr_accessor :threads
    attr_accessor :thread_limit

    attr_accessor :field_auth_loc
    attr_accessor :field_auth_isni
    attr_accessor :field_auth_oclc
    attr_accessor :field_auth_viaf

    attr_accessor :get_isni
    attr_accessor :get_loc
    attr_accessor :get_oclc
    attr_accessor :get_viaf
    attr_accessor :oclc_auth2works

    attr_accessor :local_loc_user
    attr_accessor :local_loc_pass
    attr_accessor :local_loc_url

    attr_accessor :prefixes

    attr_accessor :use_foaf
    attr_accessor :use_schema

    attr_accessor :redis4marc
    attr_accessor :redis_read
    attr_accessor :redis_write
    attr_accessor :redis

    attr_accessor :log_file
    attr_accessor :logger

    def initialize
      @debug = env_boolean('DEBUG')
      @threads = env_boolean('THREADS')
      @thread_limit = ENV['THREAD_LIMIT'] || 25

      # logging
      log_file = ENV['LOG_FILE'] || 'marc2ld.log'
      log_file = File.absolute_path log_file
      @log_file = log_file
      log_path = File.dirname log_file
      unless File.directory? log_path
        # try to create the log directory
        Dir.mkdir log_path rescue nil
      end
      begin
        log_file = File.new(@log_file, 'w+')
      rescue
        log_file = $stderr
        @log_file = 'STDERR'
      end
      @logger = Logger.new(log_file, shift_age = 'monthly')
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
      @prefixes['rdf'] = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
      @prefixes['rdfs'] = 'http://www.w3.org/2000/01/rdf-schema#'
      @prefixes['schema'] = 'http://schema.org/'
      @prefixes['owl'] = 'http://www.w3.org/2002/07/owl#'
      @prefixes['viaf'] = 'http://viaf.org/viaf/'

      # Authority parse options
      @field_auth_loc = ENV['FIELD_AUTH_LOC']
      @field_auth_isni = ENV['FIELD_AUTH_ISNI']
      @field_auth_oclc = ENV['FIELD_AUTH_OCLC']
      @field_auth_viaf = ENV['FIELD_AUTH_VIAF']

      @get_isni = env_boolean('GET_ISNI')
      @get_loc = env_boolean('GET_LOC')
      @get_viaf = env_boolean('GET_VIAF')
      @get_oclc = env_boolean('GET_OCLC')
      @oclc_auth2works = env_boolean('OCLC_AUTH2WORKS')

      # Vocabulary options
      # foaf:Person or schema:Person or both?
      @use_foaf = env_boolean('USE_FOAF')
      @use_schema = env_boolean('USE_SCHEMA') # schema.org

      # Local triple store for LOC authority data,
      # accessed via an HTTP API with basic authentication.
      # See downloads at http://id.loc.gov/download/
      @local_loc_user = ENV['LOCAL_LOC_USER']
      @local_loc_pass = ENV['LOCAL_LOC_PASS']
      loc_host = ENV['LOCAL_LOC_HOST']
      loc_port = ENV['LOCAL_LOC_PORT']
      loc_path = ENV['LOCAL_LOC_PATH']
      @local_loc_url = "http://#{loc_host}:#{loc_port}#{loc_path}"

      # Persistence options
      @redis = nil
      @redis4marc = env_boolean('REDIS4MARC')
      if @redis4marc
        @redis_url = env_boolean('REDIS_URL')
        @redis_read  = env_boolean('REDIS_READ')
        @redis_write = env_boolean('REDIS_WRITE')
        redis_config
      else
        @redis_url = nil
        @redis_read  = false
        @redis_write = false
      end
      # TODO: provide options for triple stores
    end

    def env_boolean(var)
      # check if an ENV variable is true, use false as default
      ENV[var].to_s.upcase == 'TRUE' rescue false
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

