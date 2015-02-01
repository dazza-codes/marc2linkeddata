require 'base64'

module Marc2LinkedData

  class SparqlPubmed

    attr_reader :sparql

    def initialize
      # config = Marc2LinkedData.configuration
      @sparql = SPARQL::Client.new('http://pubmed.bio2rdf.org/sparql')
    end

    # http://bio2rdf.org/pubmed_vocabulary:Author
    # dcterms:identifier   pubmed_resource:author:a71b95197f579ff09cc6d9a7d4856535
    # http://bio2rdf.org/pubmed_vocabulary:fore_name  Alison
    # http://bio2rdf.org/pubmed_vocabulary:initials  A
    # http://bio2rdf.org/pubmed_vocabulary:last_name  Callahan

    # e.g. run this SPARQL at http://pubmed.bio2rdf.org/sparql
    # SELECT DISTINCT ?author $fn $ln WHERE {
    #   ?author a <http://bio2rdf.org/pubmed_vocabulary:Author> .
    #   ?author <http://bio2rdf.org/pubmed_vocabulary:fore_name> $fn .
    #   ?author <http://bio2rdf.org/pubmed_vocabulary:last_name> $ln .
    # }
    # LIMIT 100

    # Note, might have to use first name initial for matching.

    def find_author(last_name, first_name=nil, middle_initial=nil)
      q  = 'SELECT DISTINCT ?author ?fn WHERE { '
      q += '?author a <http://bio2rdf.org/pubmed_vocabulary:Author> . '
      q += '?author <http://bio2rdf.org/pubmed_vocabulary:fore_name> ?fn . '
      q += "?author <http://bio2rdf.org/pubmed_vocabulary:last_name> \"#{last_name}\"^^<http://www.w3.org/2001/XMLSchema#string> . "
      q += '}'
      result = @sparql.query(q)
      result.each_solution do |s|
        # match on first_name? or initials?
        puts s.inspect
      end
      binding.pry
    end

  end

end


