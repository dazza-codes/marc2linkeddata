#!/usr/bin/env ruby

require_relative '../lib/boot'
require_relative '../lib/parseMarcAuthority'

REDIS4MARC = ENV['REDIS4MARC']
REDIS_RO = ENV['REDIS_RO'] || REDIS4MARC
REDIS_WO = ENV['REDIS_WO'] || REDIS4MARC

if REDIS4MARC
  # https://github.com/redis/redis-rb
  require 'hiredis'
  require 'redis'
  @redis = Redis.new # default host config
  @redis.ping
  #redis = Redis.new(:host => "10.0.1.1", :port => 6380, :db => 15)
  # storing objects in redis:
  #redis.set "foo", [1, 2, 3].to_json
  #JSON.parse(redis.get("foo"))
end

def marc2ld(marc_filename)
  ld_filename = marc_filename.gsub('.mrc','.ttl')
  ld_file = File.open(ld_filename,'w')
  write_prefixes(ld_file)
  marc_file = File.open(marc_filename,'r')
  until marc_file.eof?
    begin
      leader = ParseMarcAuthority::parse_leader(marc_file)
      if leader[:type] == 'z'
        raw = marc_file.read(leader[:length])
        record = MARC::Reader.decode(raw)
        # ParseMarcAuthority is a lazy parser, so
        # init only assigns record to an instance var.
        auth = ParseMarcAuthority.new(record)
        auth_id = "auth:#{auth.get_id}"
        triples = nil
        triples = @redis.get(auth_id) if REDIS_RO
        triples = auth.to_ttl if triples.nil?
        ld_file.write(triples)
        @redis.set(auth_id, triples) if REDIS_WO
      end
    rescue => e
      puts
      puts "ERROR"
      puts e.message
      puts e.backtrace
      puts record.to_s
      puts
      binding.pry if ENV['MARC_DEBUG']
    end
  end
  marc_file.close
  ld_file.flush
  ld_file.close
end

marc_files = []
ARGV.each do |filename|
  path = Pathname(filename)
  marc_files.push(path) if path.exist?
end
if marc_files.empty?
  puts <<HELP
#{__FILE__} marc_authority_file1.mrc [ marc_authority_file2.mrc .. marc_authority_fileN.mrc ]

Output is RDF triples in a turtle file (.ttl) for every input .mrc file.
Optional persistence services can be controlled by environment variables.

Redis Persistence - based on https://github.com/redis/redis-rb
- essential options:
  export REDIS4MARC=true # enable redis persistence (default = false)
- supplementary options:
  Set the REDIS_URL for a custom redis configuration.
  export REDIS_URL="redis://{user}:{password}@{host}:{port}/{db}"
  export REDIS_RO=true   # enable redis read-only  (default = REDIS4MARC || false)
  export REDIS_WO=true   # enable redis write-only (default = REDIS4MARC || false)
  REDIS_RO enables faster reading of triples from pre-populated redis data.
  REDIS_WO ensures current data is parsed and populated in redis.

HELP
else
end

marc_files.each do |path|
  puts "Processing: #{path}"
  marc2ld(path.to_s)
end


