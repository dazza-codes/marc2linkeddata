#!/usr/bin/env ruby

# Marc21 Authority fields are documented at
# http://www.loc.gov/marc/authority/ecadlist.html
# http://www.loc.gov/marc/authority/ecadhome.html

require 'marc'
require 'linkeddata'
require 'pry'
require 'pry-doc'

PREFIX_SUL = 'http://linked-data.stanford.edu/library/'
PREFIX_SUL_AUTH = "#{PREFIX_SUL}authority/"
PREFIX_LOC_NAMES = 'http://id.loc.gov/authorities/names/'
PREFIX_LOC_SUBJECTS = 'http://id.loc.gov/authorities/subjects/'
PREFIX_VIAF = 'http://viaf.org/viaf/'


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
def leader_read(file_handle, leader_bytes=24)
  leader = file_handle.read(leader_bytes)
  file_handle.seek(-1 * leader_bytes, IO::SEEK_CUR)
  {
    :length => leader[0..4].to_i,
    :status => leader[5],  # LEADER_STATUS_CODES[ record.leader[5] ]
    :type => leader[6],    # always 'z' for authority records
    :encoding => leader[9],  # translate letter code into ruby encoding string
    :data_address => leader[12..16].to_i,
    :complete => leader[17].include?('n')
  }
end



def parse_008(record)
  # http://www.loc.gov/marc/authority/concise/ad008.html

  field008 = record.fields.select {|f| f if f.tag == '008' }
  raise 'Invalid data in field008' if field008.length != 1
  field008 = field008.first.value

  languages = []
  languages.append('English') if ['b','e'].include? field008[8]
  languages.append('French') if ['b','f'].include? field008[8]

  rules = ''
  rules = 'EARLIER' if field008[10] == 'a'
  rules = 'AACR1' if field008[10] == 'b'
  rules = 'AACR2' if field008[10] == 'c'
  rules = 'AACR2 compatible' if field008[10] == 'd'
  rules = 'OTHER' if field008[10] == 'z'
  rules = 'N/A' if field008[10] == 'n'

  # 32 - Undifferentiated personal name
  # Whether the personal name in a name or name/title heading contained in field 100 in an established heading record or a reference record is used by one person or by two or more persons.
  # a - Differentiated personal name
  #     Personal name in field 100 is a unique name.
  # b - Undifferentiated personal name
  #     Personal name in field 100 is used by two or more persons.
  # n - Not applicable
  #     1XX heading is not a personal name or the personal name is a family name.
  # | - No attempt to code

  {
      :date => Date.strptime(field008[0..5], "%y%m%d"),
      :geographic_subdivision => field008[6], # '#', d, i, n, or '|'
      :romanization_scheme => field008[7], # a..g, n, or '|'
      :languages => languages,
      :kind => field008[9], # a..g, or '|'
      :rules => rules,
      :heading_system => field008[11],
      :series_type => field008[12],
      :series_numbered => field008[13],
      :use_1XX_for_7XX => field008[14] == 'a',
      :use_1XX_for_6XX => field008[15] == 'a',
      :use_1XX_for_4XX => field008[16] == 'a',
      :use_1XX_for_8XX => field008[16] == 'a',
      :type_subject_subdivision => field008[17],
      # 18-27 - Undefined character positions
      :type_government_agency => field008[28],
      :reference_evaluation => field008[29],
      # 30 - Undefined character position
      :record_available => field008[31] == 'a',

      # TODO: 32
      # TODO: 33

      # 34-37 - Undefined character positions
      # TODO: 38
      # TODO: 39
  }
end


# Try to use the SUL catkey and/or the OCLC control numbers, maybe SUL
# catkey in the record IRI
def get_id(record)
  # extract ID from control numbers, see
  # http://www.loc.gov/marc/authority/ad001.html
  #field001 = record.fields.select {|f| f if f.tag == '001' }.first.value
  #field003 = record.fields.select {|f| f if f.tag == '003' }.first.value
  #"#{field003}-#{field001}"
  record.fields.select {|f| f if f.tag == '001' }.first.value
end

def get_iri4sul(record)
  id = get_id(record)
  "#{PREFIX_SUL_AUTH}#{id}"
end

def get_iri(field, iri_pattern)
  begin
    iris = field.subfields.collect {|f| f.value if f.value.include? iri_pattern }
    iris.first || 'MISSING_IRI'
  rescue
    'MISSING_IRI'
  end
end

def get_iri4loc(record)
  begin
    # 920 is the loc IRI,  e.g. http://id.loc.gov/authorities/names/n42000906
    field920 = record.fields.select {|f| f if f.tag == '920' }.first
    get_iri(field920, 'id.loc.gov')
  rescue
    'MISSING_IRI'
  end
end

def get_iri4viaf(record)
  begin
    # 921 is the viaf IRI, e.g. http://viaf.org/viaf/181829329
    # Note VIAF RSS feed for changes, e.g. http://viaf.org/viaf/181829329.rss
    field921 = record.fields.select {|f| f if f.tag == '921' }.first
    get_iri(field921, 'viaf.org')
  rescue
    'MISSING_IRI'
  end
end

def get_viaf(viaf_iri)
  binding.pry
  #graph.to_ttl
end


def authority_triples(record)

  # TODO: determine the record type: person, organization, subject, etc.
  # http://www.loc.gov/marc/authority/adintro.html
  # The MARC data differentiates them according to the tag number.
  # The term 'name' refers to:
  #  X00 - Personal Name
  #  X10 - Corporate Name
  #  X11 - Meeting Name
  #  X30 - Uniform Title
  #  X51 - Jurisdiction / Geographic Name
  #
  # The term 'subject' refers to:
  #  X30 - Uniform Titles
  #  X48 - Chronological Terms
  #  X50 - Topical Terms
  #  X51 - Geographic Names
  #  X55 - Genre/Form Terms
  #
  # The term 'subject subdivision' refers to:
  # X80 - general subdivision terms
  # X81 - geographic subdivision names
  # X82 - chronological subdivision terms
  # X85 - form subdivision terms




  sul = get_iri4sul(record).gsub(PREFIX_SUL_AUTH, 'sul_auth:')
  loc_iri = get_iri4loc(record)
  viaf_iri = get_iri4viaf(record)
  viaf_rdf = RDF::Graph.load(viaf_iri + '/rdf.xml')
  viaf_iri = viaf_iri.gsub(PREFIX_VIAF, 'viaf:')

  #viaf_rdf.each_subject {|s| puts s.inspect }
  #viaf_rdf.each_statement {|s| puts s.inspect }


  binding.pry
  exit!


  triples = []
  if loc_iri =~ /names/
    loc_iri = loc_iri.gsub(PREFIX_LOC_NAMES, 'loc_names:')
    triples << "#{sul} a foaf:Person" # TODO: organization?
    triples << "; owl:sameAs #{loc_iri}"
    triples << "; owl:sameAs #{viaf_iri}" unless viaf_iri.include? 'MISSING'
    triples << " .\n"
  elsif loc_iri =~ /subjects/
    loc_iri = loc_iri.gsub(PREFIX_LOC_SUBJECTS, 'loc_subjects:')
    # TODO: what to do with subjects?
    #triples << "#{sul} a foaf:Person" # TODO: what type is this?
    #triples << "; owl:sameAs #{loc_iri}" unless loc_iri.include? 'MISSING'
    #puts "LOC: #{loc_iri}, has viaf_iri? #{viaf_iri}"
  elsif loc_iri =~ /MISSING/
    #puts "LOC: #{loc_iri}, has viaf_iri? #{viaf_iri}"
  else
    binding.pry
  end
  triples.join
end


def marc2ld4l(marc_auth_filepath)
  auth_ld4l_filepath = marc_auth_filepath.gsub('.mrc','.ttl')
  ld4l_file = File.open(auth_ld4l_filepath,'w')
  ld4l_file.write("@prefix bf: <http://bibframe.org/vocab/> .\n")
  ld4l_file.write("@prefix foaf: <http://xmlns.com/foaf/0.1/> .\n")
  ld4l_file.write("@prefix owl: <http://www.w3.org/2002/07/owl#> .\n")
  ld4l_file.write("@prefix sul_auth: <#{PREFIX_SUL_AUTH}> .\n")
  ld4l_file.write("@prefix loc_names: <#{PREFIX_LOC_NAMES}> .\n")
  ld4l_file.write("@prefix loc_subjects: <#{PREFIX_LOC_SUBJECTS}> .\n")
  ld4l_file.write("@prefix viaf: <#{PREFIX_VIAF}> .\n")
  ld4l_file.write("\n\n")
  marc_file = File.open(marc_auth_filepath,'r')
  until marc_file.eof?
    begin
      leader = leader_read(marc_file)
      raw = marc_file.read(leader[:length])
      record = MARC::Reader.decode(raw)
      if leader[:type] == 'z'
        ld4l_file.write(authority_triples(record))
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


