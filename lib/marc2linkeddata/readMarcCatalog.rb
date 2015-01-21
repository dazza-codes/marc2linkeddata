#!/usr/bin/env ruby

require 'marc'
require 'linkeddata'
require 'pry'

#EXAMPLE_RECORD_FILE='../marc/catalog/stf.00.mrc'
EXAMPLE_RECORD_FILE='../marc/catalog/stf.51.mrc'

## reading records from a batch file
#reader = MARC::Reader.new(EXAMPLE_RECORD_FILE, :external_encoding => "MARC-8")
#reader = MARC::Reader.new(EXAMPLE_RECORD_FILE, :external_encoding => "UTF-8", :validate_encoding => true)

#reader = MARC::ForgivingReader.new(EXAMPLE_RECORD_FILE)

handle = File.new(EXAMPLE_RECORD_FILE)
#=> #<File:marc/authority/stf_auth.00.mrc>
rec_length = handle.read(5).to_i
#=> 774
handle.rewind
raw = handle.read(rec_length)
record = MARC::Reader.decode(raw)

# From http://www.loc.gov/marc/authority/adleader.html
# System-Generated Elements - The following Leader elements are usually system generated:
#
# 00-04 	Logical record length
#
#    05 - Record status:
#     a - Increase in encoding level
#     c - Corrected or revised
#     d - Deleted
#     n - New
#     o - Obsolete
#     s - Deleted; heading split into two or more headings
#     x - Deleted; heading replaced by another heading
#
#    06 - Type of record
#     z - Authority data
#
# 07-08 	Undefined character positions
#
#    09 - Character coding scheme
#     # - MARC-8
#     a - UCS/Unicode
#
#    10 	Indicator count
#     2 - Number of character positions used for indicators
#
#    11 	Subfield code count
#     2 - Number of character positions used for a subfield code
#
# 12-16 	Base address of data
#     [number] - Length of Leader and Directory
#
#    17 - Encoding level
#     n - Complete authority record
#     o - Incomplete authority record
#
# 20-23 	Entry map
#
# 18-19 - Undefined character positions
#
#    20 - Length of the length-of-field portion
#     4 - Number of characters in the length-of-field portion of a Directory entry
#
#    21 - Length of the starting-character-position portion
#     5 - Number of characters in the starting-character-position portion of a Directory entry
#
#    22 - Length of the implementation-defined portion
#     0 - Number of characters in the implementation-defined portion of a Directory entry
#
# It is common for default values in other Leader elements to be generated automatically as well.
# Capitalization - Alphabetic codes are input as lower case letters.
#
# example:
#record.leader
#=> "00774cz  a2200253n  4500"
# 00-04: '00774' - record length
# 05:    'c' - corrected or revised
# 06:    'z' - always 'z' for authority records
# 09:    'a' - UCS/Unicode
# 12-16: '00253' - base address of data, Length of Leader and Directory
# 17:    'n' - Complete authority record
LEADER_STATUS_CODES = {
  'a' => 'Increase in encoding level',
  'c' => 'Corrected or revised',
  'd' => 'Deleted',
  'n' => 'New',
  'o' => 'Obsolete',
  's' => 'Deleted; heading split into two or more headings',
  'x' => 'Deleted; heading replaced by another heading'
}
def leader_parse(record)
  leader = {
    :length => record.leader[0..4].to_i,
    :status => record.leader[5],  # LEADER_STATUS_CODES[ record.leader[5] ]
    :type => record.leader[6],    # always 'z' for authority records
    :encoding => record.leader[9],  # TODO: translate letter code into ruby encoding string
    :data_address => record.leader[12..16].to_i,
    :complete => record.leader[17].include?('n')
  }
end


# Stanford Resource keys and Ckeys can collide. They are only unique within their own set.
#
# When I do a catalogdump for ckey 6809804 I see:
#
# .948.   |hNO HOLDINGS IN STF - 7 OTHER HOLDINGS
#
# When we do a catalogdump for searchworks we filter the results to only export
# records with holdings, and not those things which are on order or "shadowed"
# i.e. hidden from public view, although we still have the bibliographic data in
# the database. When I extracted the records for conversion I selected all of
# them.
#
# - Josh


# Create SUL LOD...
SUL_URI = RDF::URI.new('http://linked-data.stanford.edu/library/')

# extract catalog key from field 001 (use the first one)
field001 = record.fields.select {|f| f if f.tag == '001' }.first
cat_key = field001.value.strip
CAT_URI = SUL_URI.join("catalog/#{cat_key}")

# TODO: Evaluate whether cat_key is in SearchWorks, e.g.
# "http://searchworks.stanford.edu/catalog/#{cat_key}"
# http://searchworks.stanford.edu/catalog/7106054

# TODO: extract 035a for OCLC master control number.
# TODO: map the OCLC to the OCLC work number.
field035 = record.fields.select {|f| f if f.tag == '035' }


binding.pry
exit!


#There is nothing in the MARC record itself to indicate that a holding is
#'shadowed' (not available for public view), but one idea to handle them is
#to supply a list of shadowed ckeys and that list could easily be transformed
#
#into a list of triples like this:
#	<http://linked-data.stanford.edu/library/catalog/{cKey}> <rdf:Property> <http://linked-data.stanford.edu/library/catalog/isShadowed>
#...or what ever predicate and object you want to use. Then you can load those into the triple store.

# .948.   |hNO HOLDINGS IN STF - 7 OTHER HOLDINGS
# When we do a catalogdump for searchworks we filter the results to only export
# records with holdings, and not those things which are on order or "shadowed"
# i.e. hidden from public view, although we still have the bibliographic data in
# the database. When I extracted the records for conversion I selected all of
# them.
field948 = record.fields.select {|f| f if f.tag == '948' }
holdings = field948.first.value


# TODO: construct RDF model, see http://blog.datagraph.org/2010/03/rdf-for-ruby
# RDF::Literal.new("Hello!", :language => :en)
#
lod = {
  :id => cat_uri,
  :oclc => oclc4loc.collect {|uri| RDF::URI.new(uri) },
}

binding.pry
exit!

#for record in reader
#  # print out field 245 subfield a
#  puts record['245']['a']
#end

