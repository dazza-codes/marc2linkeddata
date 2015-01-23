require 'dotenv'
Dotenv.load

require 'addressable/uri'
require 'json'
require 'linkeddata'
require 'marc'
require 'rdf/4store'
require 'ruby-progressbar'

require 'pry'
require 'pry-doc'

require_relative 'marc2linkeddata/configuration'
require_relative 'marc2linkeddata/resource'
require_relative 'marc2linkeddata/loc'
require_relative 'marc2linkeddata/viaf'
require_relative 'marc2linkeddata/oclc_identity'
require_relative 'marc2linkeddata/oclc_creative_work'
require_relative 'marc2linkeddata/oclc_work'
require_relative 'marc2linkeddata/parseMarcAuthority'
#require_relative 'marc2linkeddata/parseMarcCatalog'


module Marc2LinkedData

  # configuration at the module level, see
  # http://brandonhilkert.com/blog/ruby-gem-configuration-patterns/

  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.http_head_request(url)
    uri = URI.parse(url)
    Net::HTTP.start(uri.host, uri.port) {|http| req = Net::HTTP::Head.new(uri); http.request req }
  end

  def self.write_prefixes(file)
    @configuration.prefixes.each_pair {|k,v| file.write "@prefix #{k}: <#{v}> .\n" }
    file.write("\n\n")
  end

end

