
require 'pry'
require 'linkeddata'
require_relative 'boot'

class Auth

  attr_accessor :iri

  def initialize(iri=nil)
    if iri.instance_of? NilClass
      @iri = nil
    elsif iri.instance_of? String
      if iri == ''
        @iri = nil
      else
        @iri = URI.parse(iri) rescue nil
      end
    elsif iri.instance_of? URI::Generic
      # don't accept this input
      @iri = nil
    elsif iri.instance_of? URI::HTTP
      @iri = iri
    elsif iri.instance_of? RDF::URI
      # coerce it to URI::HTTP
      @iri = URI.parse(iri.to_s) rescue nil
    else
      @iri = nil
    end
    if @iri.to_s.end_with? '/'
      iri = @iri.to_s.gsub(/\/$/,'')
      @iri = URI.parse(iri) rescue nil
    end
  end

  def rdf_valid?
    # TODO: convert this to an RDF.rb graph query
    return nil if @iri.nil?
    return @rdf_valid unless @rdf_valid.nil?
    iris = rdf.subjects.select {|s| s if s == @iri.to_s }
    @rdf_valid = iris.to_set.length == 1
  end

  def rdf_find_object(id)
    # TODO: convert this to an RDF.rb graph query
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
    # TODO: convert this to an RDF.rb graph query
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

end


