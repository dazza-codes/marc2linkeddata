#!/usr/bin/env ruby

# Marc21 Authority fields are documented at
# http://www.loc.gov/marc/authority/ecadlist.html
# http://www.loc.gov/marc/authority/ecadhome.html

require 'json'
require 'linkeddata'
require 'marc'
require 'pry'
require 'pry-doc'

require_relative 'boot'
require_relative 'parseMarcAuthority'

# TODO: enable the redis cache for PROD
USE_CACHE = false # use redis in prod, not in dev
if USE_CACHE
  # https://github.com/redis/redis-rb
  require 'hiredis'
  require 'redis'
  @redis = Redis.new # default host config
  #redis = Redis.new(:host => "10.0.1.1", :port => 6380, :db => 15)
  # storing objects in redis:
  #redis.set "foo", [1, 2, 3].to_json
  #JSON.parse(redis.get("foo"))
end

def marc2ld4l(marc_auth_filepath)
  auth_ld4l_filepath = marc_auth_filepath.gsub('.mrc','.ttl')
  ld4l_file = File.open(auth_ld4l_filepath,'w')
  write_prefixes(ld4l_file)
  marc_file = File.open(marc_auth_filepath,'r')
  until marc_file.eof?
    begin
      #leader = parse_leader(marc_file)
      leader = ParseMarcAuthority::parse_leader(marc_file)
      raw = marc_file.read(leader[:length])
      record = MARC::Reader.decode(raw)
      if leader[:type] == 'z'
        auth = ParseMarcAuthority.new(record)
        auth_id = "sul_auth:#{auth.get_id}"
        triples = nil
        triples = @redis.get(auth_id) if USE_CACHE
        triples = auth.to_ttl if triples.nil?
        ld4l_file.write(triples)
        @redis.set(auth_id, triples) if USE_CACHE
      end
    rescue => e
      puts
      puts "ERROR"
      puts e.message
      puts e.backtrace
      puts record.to_s
      puts
      #binding.pry
    end
  end
  marc_file.close
  ld4l_file.flush
  ld4l_file.close
end

marc_files = []
ARGV.each do |filename|
  path = Pathname(filename)
  marc_files.push(path) if path.exist?
end
if marc_files.empty?
  puts "#{__FILE__} marc_authority_file1.mrc [ marc_authority_file2.mrc .. marc_authority_fileN.mrc ]"
else
end

marc_files.each do |path|
  puts "Processing: #{path}"
  marc2ld4l(path.to_s)
end

## reading records from a batch file
#reader = MARC::Reader.new(EXAMPLE_AUTH_RECORD_FILE, :external_encoding => "MARC-8")
#reader = MARC::Reader.new(EXAMPLE_AUTH_RECORD_FILE, :external_encoding => "UTF-8", :validate_encoding => true)
#reader = MARC::ForgivingReader.new(EXAMPLE_AUTH_RECORD_FILE)
#for record in reader
#  # print out field 245 subfield a
#  puts record['245']['a']
#end


