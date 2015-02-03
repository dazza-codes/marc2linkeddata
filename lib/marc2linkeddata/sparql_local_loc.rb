require 'base64'

module Marc2LinkedData

  class SparqlLocalLoc < Sparql

    def initialize(uri)
      config = Marc2LinkedData.configuration
      uri = config.local_loc_url
      # local LOC SPARQL client
      auth_code = Base64.encode64("#{config.local_loc_user}:#{config.local_loc_pass}").chomp
      headers = {
          'Accept' => 'application/sparql-results+json',
          'Authorization' => "Basic #{auth_code}",
      }
      @sparql = SPARQL::Client.new(uri, {headers: headers} )
    end

    def auth(auth_uri)
      result = @sparql.query("SELECT * WHERE { <#{auth_uri}> ?p ?o }")
      result.each_solution {|s| puts s.inspect }
      binding.pry
    end

  end

end


