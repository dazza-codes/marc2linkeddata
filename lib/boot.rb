require 'pry'
require 'pry-doc'


# TODO: enable ENV config
# ENV['USE_CACHE']  # use redis, mongo, or triple store
# ENV['USE_HTTP']   # resolve VIAF or ISNI


def http_head_request(url)
  uri = URI.parse(url)
  Net::HTTP.start(uri.host, uri.port) {|http| req = Net::HTTP::Head.new(uri); http.request req }
end

# RDF prefixes
PREFIX_BF = 'http://bibframe.org/vocab/'
PREFIX_SUL = 'http://linked-data.stanford.edu/library/'
PREFIX_SUL_AUTH = "#{PREFIX_SUL}authority/"
PREFIX_LOC_NAMES = 'http://id.loc.gov/authorities/names/'
PREFIX_LOC_SUBJECTS = 'http://id.loc.gov/authorities/subjects/'
PREFIX_VIAF = 'http://viaf.org/viaf/'
PREFIX_ISNI = 'http://www.isni.org/isni/'
PREFIX_FOAF = 'http://xmlns.com/foaf/0.1/'

def write_prefixes(file)
  file.write("@prefix bf: <#{PREFIX_BF}> .\n")
  file.write("@prefix foaf: <#{PREFIX_FOAF}> .\n")
  file.write("@prefix isni: <#{PREFIX_ISNI}> .\n")
  file.write("@prefix loc_names: <#{PREFIX_LOC_NAMES}> .\n")
  file.write("@prefix loc_subjects: <#{PREFIX_LOC_SUBJECTS}> .\n")
  file.write("@prefix owl: <http://www.w3.org/2002/07/owl#> .\n")
  file.write("@prefix sul_auth: <#{PREFIX_SUL_AUTH}> .\n")
  file.write("@prefix viaf: <#{PREFIX_VIAF}> .\n")
  file.write("\n\n")
end

