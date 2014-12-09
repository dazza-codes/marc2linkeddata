#!/usr/bin/env ruby

require 'marc'
require 'linkeddata'
require 'pry'

EXAMPLE_AUTH_RECORD_FILE='../marc/authority/stf_auth.00.mrc'

## reading records from a batch file
#reader = MARC::Reader.new(EXAMPLE_AUTH_RECORD_FILE, :external_encoding => "MARC-8")
#reader = MARC::Reader.new(EXAMPLE_AUTH_RECORD_FILE, :external_encoding => "UTF-8", :validate_encoding => true)

#reader = MARC::ForgivingReader.new(EXAMPLE_AUTH_RECORD_FILE)

handle = File.new(EXAMPLE_AUTH_RECORD_FILE)
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



# TODO: extract cat-key
cat_key = ''
binding.pry

#record.fields.collect {|f| f if f.tag.start_with? '9' }

# 920 is the loc IRI,  e.g. http://id.loc.gov/authorities/names/n42000906
field920 = record.fields.select {|f| f if f.tag == '920' }.first
# if select fails: field920 = [].first = nil
iris4loc = field920.subfields.collect {|f| f.value if f.value.include? 'id.loc.gov' }

# 921 is the viaf IRI, e.g. http://viaf.org/viaf/181829329
# Note VIAF RSS feed for changes, e.g. http://viaf.org/viaf/181829329.rss
field921 = record.fields.select {|f| f if f.tag == '921' }.first
# if select fails: field921 = [].first = nil
iris4viaf = field921.subfields.collect {|f| f.value if f.value.include? 'viaf.org' }


#TODO: Try to use the SUL catkey and/or the OCLC control numbers, maybe SUL
#catkey in the record IRI

# TODO: Create SUL LOD...
SUL_LOD_PREFIX = "http://linked-data.stanford.edu/library"

lod = {
  :id => "#{SUL_LOD_PREFIX}/#{cat_key}",
  :loc => iris4loc,
  :viaf => iris4viaf
}

binding.pry
exit!

#for record in reader
#  # print out field 245 subfield a
#  puts record['245']['a']
#end


# #<MARC::Record:0x007f6432e72c58
#  @fields=
#   [#<MARC::ControlField:0x007f6432e72320 @tag="001", @value="N42000906">,
#    #<MARC::ControlField:0x007f6432e71d30 @tag="001", @value="n  42000906">,
#    #<MARC::ControlField:0x007f6432e71718 @tag="003", @value="DLC">,
#    #<MARC::ControlField:0x007f6432e71218 @tag="005", @value="20060413052035.0">,
#    #<MARC::ControlField:0x007f6432e70d40 @tag="008", @value="821221n| acabaaaan          |a aaa      ">,
#    #<MARC::DataField:0x007f6432e708e0
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e70570 @code="a", @value="n  42000906 ">,
#       #<MARC::Subfield:0x007f6432e704a8 @code="z", @value="n  82089585">],
#     @tag="010">,
#    #<MARC::DataField:0x007f6432e70228
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=[#<MARC::Subfield:0x007f6432e6fe68 @code="a", @value="(OCoLC)oca00000863">],
#     @tag="035">,
#    #<MARC::DataField:0x007f6432e6faf8
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e6f328 @code="a", @value="DLC">,
#       #<MARC::Subfield:0x007f6432e6f210 @code="b", @value="eng">,
#       #<MARC::Subfield:0x007f6432e6f0f8 @code="c", @value="DLC">,
#       #<MARC::Subfield:0x007f6432e6ee78 @code="d", @value="DLC">,
#       #<MARC::Subfield:0x007f6432e6ed60 @code="d", @value="OCoLC">],
#     @tag="040">,
#    #<MARC::DataField:0x007f6432e6cda8
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e6c830 @code="a", @value="PG1037">,
#       #<MARC::Subfield:0x007f6432e6c718 @code="b", @value=".S66 1981">],
#     @tag="050">,
#    #<MARC::DataField:0x007f6432e6c240
#     @indicator1="1",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e6bcf0 @code="a", @value="Stanev, Emilii\xCD\xA1an.">,
#       #<MARC::Subfield:0x007f6432e6bc50 @code="t", @value="Works.">,
#       #<MARC::Subfield:0x007f6432e6ba70 @code="f", @value="1981">],
#     @tag="100">,
#    #<MARC::DataField:0x007f6432e6b598
#     @indicator1="1",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e6aa08 @code="a", @value="Stanev, Emilii\xCD\xA1an.">,
#       #<MARC::Subfield:0x007f6432e6a850 @code="t", @value="S\xC5\xADbrani s\xC5\xADchinenii\xCD\xA1a v sedem toma.">,
#       #<MARC::Subfield:0x007f6432e6a710 @code="f", @value="1981">],
#     @tag="400">,
#    #<MARC::DataField:0x007f6432e6a0a8
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e695e0 @code="a", @value="t. 1">, #<MARC::Subfield:0x007f6432e69338 @code="5", @value="DLC">],
#     @tag="642">,
#    #<MARC::DataField:0x007f6432e68d48
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e682a8 @code="a", @value="Sofii\xCD\xA1a">,
#       #<MARC::Subfield:0x007f6432e680a0 @code="b", @value="B\xC5\xADlgarski pisatel">],
#     @tag="643">,
#    #<MARC::DataField:0x007f6432e63a00
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e63398 @code="a", @value="f">, #<MARC::Subfield:0x007f6432e63230 @code="5", @value="DLC">],
#     @tag="644">,
#    #<MARC::DataField:0x007f6432e62dd0
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e62920 @code="a", @value="t">, #<MARC::Subfield:0x007f6432e62830 @code="5", @value="DLC">],
#     @tag="645">,
#    #<MARC::DataField:0x007f6432e625b0
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e62268 @code="a", @value="c">, #<MARC::Subfield:0x007f6432e621a0 @code="5", @value="DLC">],
#     @tag="646">,
#    #<MARC::DataField:0x007f6432e61f20
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=
#      [#<MARC::Subfield:0x007f6432e61b88
#        @code="a",
#        @value="Stanev, E. S\xC5\xADbrani s\xC5\xADchinenii\xCD\xA1a v sedem toma, 1981-">],
#     @tag="670">,
#    #<MARC::DataField:0x007f6432e618b8
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=[#<MARC::Subfield:0x007f6432e61570 @code="a", @value="http://id.loc.gov/authorities/names/n42000906">],
#     @tag="920">,
#    #<MARC::DataField:0x007f6432e61340
#     @indicator1=" ",
#     @indicator2=" ",
#     @subfields=[#<MARC::Subfield:0x007f6432e60fa8 @code="a", @value="http://viaf.org/viaf/181829329">],
#     @tag="921">],
#  @leader="00774cz  a2200253n  4500">
# 


