
module Marc2LinkedData

  class SparqlDbpedia < Sparql

    def initialize
      super('http://dbpedia.org/sparql')
    end

    # def sparql_dbpedia(query)
    #   dbpedia.query(query)
    #   # result = dbpedia.query('ASK WHERE { ?s ?p ?o }')
    #   # puts result.inspect   #=> true or false
    #   # result = dbpedia.query('SELECT * WHERE { ?s ?p ?o } LIMIT 10')
    #   # result.each_solution {|s| puts s.inspect }
    # end

  end

end


