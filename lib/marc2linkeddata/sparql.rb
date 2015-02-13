
module Marc2LinkedData

  class Sparql

    attr_reader :sparql

    def initialize(uri)
      # https://github.com/ruby-rdf/sparql-client
      @sparql = SPARQL::Client.new(uri)
    end

  end

end

