require 'base64'

module Marc2LinkedData

  class Sparql

    # https://github.com/ruby-rdf/sparql-client

    # attr_reader :config
    attr_reader :dbpedia
    attr_reader :local_loc

    def initialize
      config = Marc2LinkedData.configuration
      @dbpedia = SPARQL::Client.new('http://dbpedia.org/sparql')
      # local LOC SPARQL client
      auth_code = Base64.encode64("#{config.local_loc_user}:#{config.local_loc_pass}").chomp
      headers = {
          'Accept' => 'application/sparql-results+json',
          'Authorization' => "Basic #{auth_code}",
      }
      @local_loc = SPARQL::Client.new(config.local_loc_url, {headers: headers} )
    end

    def local_loc_auth(auth_uri)
      result = local_loc.query("SELECT * WHERE { <#{auth_uri}> ?p ?o }")
      result.each_solution {|s| puts s.inspect }
      binding.pry
    end

    # def sparql_dbpedia(query)
    #   dbpedia.query(query)
    #   # result = dbpedia.query('ASK WHERE { ?s ?p ?o }')
    #   # puts result.inspect   #=> true or false
    #   # result = dbpedia.query('SELECT * WHERE { ?s ?p ?o } LIMIT 10')
    #   # result.each_solution {|s| puts s.inspect }
    # end


    # For reference, note that there is an allegrograph ruby gem, see
    # https://github.com/emk/rdf-agraph

    # For reference, note that there is a ruby gem for RDF on mongodb, see
    # https://rubygems.org/gems/rdf-mongo






  end

end


