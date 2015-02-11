require_relative 'cap_db'

module Marc2LinkedData

  class Cap

    attr_accessor :db

    def initialize
      @db = Marc2LinkedData::CapDb.new
    end
  end

end

