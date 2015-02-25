require 'dotenv'
Dotenv.load

require 'addressable/uri'
require 'json'
require 'rest-client'
RestClient.proxy = ENV['http_proxy'] unless ENV['http_proxy'].nil?
require 'ruby-progressbar'

require 'thread'
require 'parallel'

require 'marc'
require 'linkeddata'
require 'rdf/4store'
require 'rdf/mongo'

require 'pry'
require 'pry-doc'

require_relative 'marc2linkeddata/configuration'
require_relative 'marc2linkeddata/utils'

require_relative 'marc2linkeddata/resource'
require_relative 'marc2linkeddata/bnf'
require_relative 'marc2linkeddata/isni'
require_relative 'marc2linkeddata/lib_auth'
require_relative 'marc2linkeddata/loc'
require_relative 'marc2linkeddata/viaf'

if ENV['SUL_CAP_ENABLED'].to_s.upcase == 'TRUE'
  require_relative 'marc2linkeddata/cap'
end

require_relative 'marc2linkeddata/oclc_resource'
require_relative 'marc2linkeddata/oclc_identity'
require_relative 'marc2linkeddata/oclc_creative_work'
require_relative 'marc2linkeddata/oclc_work'

require_relative 'marc2linkeddata/sparql'
require_relative 'marc2linkeddata/sparql_dbpedia'
require_relative 'marc2linkeddata/sparql_pubmed'

require_relative 'marc2linkeddata/parseMarcAuthority'
#require_relative 'marc2linkeddata/parseMarcCatalog'



