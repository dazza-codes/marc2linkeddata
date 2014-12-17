
require 'pry'
require 'linkeddata'
require "addressable/uri"
require_relative 'boot'

class Auth

  attr_accessor :iri

  def initialize(iri=nil)
    if iri =~ /\A#{URI::regexp}\z/
      iri = Addressable::URI.parse(iri.to_s) rescue nil
    end
    # Strip off any trailing '/'
    if iri.to_s.end_with? '/'
      iri = iri.to_s.gsub(/\/$/,'')
      iri = Addressable::URI.parse(iri.to_s) rescue nil
    end
    raise 'invalid iri' unless iri.instance_of? Addressable::URI
    @iri = iri
  end

  def id
    return nil if @iri.nil?
    @iri.basename
  end

  def rdf
    return nil if @iri.nil?
    return @rdf unless @rdf.nil?
    @rdf = RDF::Graph.load(@iri)
  end

  def rdf_valid?
    return nil if @iri.nil?
    iri_types.length > 0
  end

  def iri_types
    rdf.query(SPARQL.parse("SELECT * WHERE { <#{@iri}> a ?o }"))
  end

  def rdf_find_object(id)
    # TODO: convert this to an RDF.rb graph query?
    return nil if @iri.nil?
    return nil unless rdf_valid?
    rdf.each_statement do |s|
      if s.subject == @iri.to_s
        return s.object if s.object.to_s =~ Regexp.new(id, Regexp::IGNORECASE)
      end
    end
    nil
  end

  def rdf_find_subject(id)
    # TODO: convert this to an RDF.rb graph query?
    return nil if @iri.nil?
    return nil unless rdf_valid?
    rdf.each_statement do |s|
      return s.subject if s.subject.to_s =~ Regexp.new(id, Regexp::IGNORECASE)
    end
    nil
  end

  def resolve_external_auth(url)
    begin
      res = http_head_request(url)
      case res.code
        when '200'
          # TODO: convert puts to logger?
          puts "SUCCESS: #{@iri}\t-> #{url}"
          return url
        when '301'
          #301 Moved Permanently
          url = res['location']
          puts "SUCCESS: #{@iri}\t-> #{url}"
          return url
        when '302','303'
          #302 Moved Temporarily
          #303 See Other
          # Use the current URL, most get requests will follow a 302 or 303
          puts "SUCCESS: #{@iri}\t-> #{url}"
          return url
        when '404'
          puts "FAILURE: #{@iri}\t// #{url}"
          return nil
        else
          # WTF
          binding.pry
          return nil
      end
    rescue
      nil
    end
  end

  def same_as
    same_as_url = 'http://sameas.org/rdf?uri=' + URI.encode(@iri.to_s)
    RDF::Graph.load(same_as_url)
  end

  def same_as_array
    same_as.query(same_as_query).collect {|s| s[:o] }
  end

  def same_as_query
    SPARQL.parse("SELECT * WHERE { <#{@iri}> <http://www.w3.org/2002/07/owl#sameAs> ?o }")
  end

end

