
require_relative 'includes'

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
    response = nil
    begin
      response = RestClient.head(url)
    rescue
      @configuration.logger.error "RestClient.head failed for #{url}"
      begin
        response = RestClient.get(url)
      rescue
        @configuration.logger.error "RestClient.get failed for #{url}"
      end
    end
    response
  end

  def self.write_prefixes(file)
    @configuration.prefixes.each_pair {|k,v| file.write "@prefix #{k}: <#{v}> .\n" }
    file.write("\n\n")
  end

end

