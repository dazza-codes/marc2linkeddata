require 'logger'
require 'mysql'
require 'sequel'

module Marc2LinkedData

  # An interface to an SQL database using Sequel
  # @see http://sequel.jeremyevans.net/documentation.html Sequel RDoc
  # @see http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html Sequel README
  # @see http://sequel.jeremyevans.net/rdoc/files/doc/code_order_rdoc.html Sequel code order
  class CapDb

    @@log = Logger.new('log/cap_db.log')

    attr_accessor :db
    attr_accessor :db_config

    def self.log_model_info(m)
      @@log.info "table: #{m.table_name}, columns: #{m.columns}, pk: #{m.primary_key}"
    end

    def initialize
      @db_config = {}
      @db_config['host'] = ENV['SUL_CAP_DB_HOST'] || 'localhost'
      @db_config['port'] = ENV['SUL_CAP_DB_PORT'] || '3306'
      @db_config['user'] = ENV['SUL_CAP_DB_USER'] || 'capUser'
      @db_config['password'] = ENV['SUL_CAP_DB_PASSWORD'] || 'capPass'
      @db_config['database'] = ENV['SUL_CAP_DB_DATABASE'] || 'cap'
      options = @db_config.merge(
          {
              :encoding => 'utf8',
              :max_connections => 10,
              :logger => @@log
          })
      @db = Sequel.mysql(options)
      @db.extension(:pagination)
      # Ensure the connection is good on startup, raises exceptions on failure
      puts "#{@db} connected: #{@db.test_connection}"
    end

  end

end

