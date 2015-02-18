
marc2linkeddata
===============

Utilities for translating MARC21 into linked data.  The project has
focused on authority records (as of 2015).

It has config options that can be enabled to increase the amount of data retrieved.
All config options are set by environment variables.  The .env_example file documents
the options available and how to use a .env file; the `marc2LD_config` utility will
copy the .env_example file provided into the current path.

Without any HTTP retrieval of RDF metadata, using only data in a MARC record, it can
translate 100,000 authority records in about 5-6 min on a current laptop system.  The
config options allow specification of MARC fields that may already contain resource links.
With RDF retrieval options enabled, it can take a lot longer (days; and the
RDF providers may not be happy about a barrage of requests).

It may help to enable threading for concurrent processing.  The concurrency is provided
by the ruby parallel gem, which can automatically optimise concurrent threads or processes.
It can process 100,000 authority records in under 2 min (without any RDF retrieval).

The processing involves substantial file IO and, when enabled, network IO also.  With
about 100,000 records in a .mrc file, all records can be loaded into memory and processed
in a serial list or concurrently.  With regard to file IO, it is the most expensive
operation in the MARC-only mode (it may help to use a drive with high IO performance).
In the RDF retrieval mode, where network IO becomes more important, it may help
to enable threads for concurrent retrieval of RDF resources.  However, it's still
relatively slow (exploring options for caching and local downloads of RDF data).

The current output is to the file system, but it should be easy to incorporate
and configure alternatives by using the RDF.rb facilities for connecting to a
repository.  A minor attempt was explored to use redis for caching, but that
exploration hasn't matured much, mainly because there is no 'cache-expiry' data
yet and because it would be better to use an RDF.rb extension of some
kind (for redis, mongodb, etc) or to use a triple store/solr platform.

TODO: Develop on additional example datasets, to evaluate the generality and robustness
of the utilities.

TODO: A significant problem to solve is effective caching or mirrors for linked data.
The retrieval should inspect any HTTP cache headers that might be available and
adding PROVO to the linked-data graph generated for each record.

TODO: Provide system platform options, like docker, to package the application and
make it easier to scale out the processing.  Consider https://www.packer.io/intro/index.html

Optional Dependencies

  - http://4store.org/
  - http://www.mongodb.org/
  - http://redis.io/
  - see notes below
  - see also:
    - http://marmotta.apache.org
    - http://stardog.com

Install

    gem install marc2linkeddata

Install with rbenv (on linux)

    cd
    git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
    source .bash_profile
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    rbenv install 2.2.0   # or the latest ruby available
    rbenv global 2.2.0
    rbenv rehash
    gem install bundle
    gem install marc2linkeddata

Configure

    # set env values and/or create or modify a .env file
    # see the .env_example file for details.
    # Performance will slow with more retrieval of linked
    # data resources, such as OCLC works for authorities.
    marc2LD_config

Console Exploration

    # First set configuration parameters (see details above).
    # Then enter the pry REPL console, which requires the
    # gem and loads the configuration.
    marc2LD_console
    > loc = Marc2LinkedData::Loc.new 'http://id.loc.gov/authorities/names/n79044798'
    > loc.id
    => "n79044798"
    > #
    > # retrieve RDF from LOC
    > loc.rdf
    => #<RDF::Graph:0x3fe88de67494(default)>
    > # the RDF is an in-memory graph
    > loc.rdf.to_ttl
    => snipped for brevity
    > #
    > # Various attributes derived from the RDF
    > loc.label
    => "Byrnes, Christopher I., 1949-"
    > loc.deprecated?
    => false
    > loc.person?
    => true
    > loc.corporation?
    => false
    > loc.conference?
    => false
    > loc.geographic?
    => false
    > loc.name_title?
    => false
    > loc.uniform_title?
    => false
    > #
    > # Try to retrieve additional linked data resources:
    > loc.get_viaf
    => "http://viaf.org/viaf/108317368/"
    > loc.get_oclc_identity
    => "http://www.worldcat.org/identities/lccn-n79044798/"
    > #
    > # Don't just read this, do the homework:
    > # There are similar classes for VIAF, ISNI and OCLC entities,
    > # explore the code base for more details and figure out how
    > # to use that VIAF IRI to construct a Viaf object, and
    > # then use it to get more ISNI linked data 8-)


Scripting

    # First configure (see details above).
    # Translate a MARC21 authority file to a turtle file.
    # It's assumed that '*.mrc' files contain multiple MARC21
    # records and the record identifier is configured in the
    # ENV['FIELD_AUTH_ID'] value, it defaults to MARC field 001.
    # marcAuthority2LD [ authfile1.mrc .. authfileN.mrc ]
    marcAuthority2LD auth.mrc

    # To provide one-off config values on the command line, set
    # the environment variable first; e.g. the following turns of
    # debug mode, processes 20 records from auth.mrc, using
    # concurrent processing.
    DEBUG=false TEST_RECORDS=20 THREADS=true marcAuthority2LD auth.mrc

    # Check the syntax of the output turtle files.
    touch turtle_syntax_checks.log
    for f in $(find ./auth_turtle/ -type f -name '.ttl'); do
      rapper -c -i turtle $f >>  turtle_syntax_checks.log 2>&1
    done

Example Output Files

- In this example, only data in the MARC record was used, without any RDF link
  resolution or retrieval.  The example MARC record already contained links to
  VIAF and ISNI IRIs (these 9xx MARC fields are identified in the configuration).

        @prefix owl: <http://www.w3.org/2002/07/owl#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix schema: <http://schema.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        <http://linked-data.stanford.edu/library/authority/N79044798> a schema:Person;
           schema:name "Byrnes, Christopher I.,";
           owl:sameAs <http://id.loc.gov/authorities/names/n79044798>,
             <http://viaf.org/viaf/108317368>,
             <http://www.isni.org/0000000109311081> .

- In this example, all the RDF link resolution and retrieval was enabled.  Also, the
  OCLC works for this authority were resolved.  The result is an 'authority index' into LOD,
  including associated works.  Although some of the RDF was retrieved in the process (and
  could be cached in a local triple store), the output record is designed to be an LOD index
  only.  The index could be stored in a local triple store, to be leveraged by local clients
  that may retrieve and use additional data from the RDF links.  Sharing such an 'LOD index'
  in a distributed network database could be very useful and open opportunities for institutions
  to collaborate on scaling the link resolution and maintenance issues.

        @prefix owl: <http://www.w3.org/2002/07/owl#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix schema: <http://schema.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        <http://linked-data.example.org/library/authority/N79044798> a schema:Person;
           schema:familyName "Byrnes";
           schema:givenName "Christopher Ian",
             "Christopher I";
           schema:name "Byrnes, Christopher I., 1949-";
           owl:sameAs <http://id.loc.gov/authorities/names/n79044798>,
             <http://viaf.org/viaf/108317368>,
             <http://www.isni.org/0000000109311081> .
        <http://id.loc.gov/authorities/names/n79044798> owl:sameAs <http://www.worldcat.org/identities/lccn-n79044798> .
        <http://www.worldcat.org/identities/lccn-n79044798> rdfs:seeAlso <http://www.worldcat.org/oclc/747413718>,
             <http://www.worldcat.org/oclc/017649403>,
             <http://www.worldcat.org/oclc/004933024>,
             <http://www.worldcat.org/oclc/007170722>,
             <http://www.worldcat.org/oclc/006626542>,
             <http://www.worldcat.org/oclc/050868185>,
             <http://www.worldcat.org/oclc/013525712>,
             <http://www.worldcat.org/oclc/013700764>,
             <http://www.worldcat.org/oclc/036387153>,
             <http://www.worldcat.org/oclc/013525674>,
             <http://www.worldcat.org/oclc/013700768>,
             <http://www.worldcat.org/oclc/018380395>,
             <http://www.worldcat.org/oclc/018292079>,
             <http://www.worldcat.org/oclc/023969230>,
             <http://www.worldcat.org/oclc/035911289>,
             <http://www.worldcat.org/oclc/495781917>,
             <http://www.worldcat.org/oclc/727657045>,
             <http://www.worldcat.org/oclc/782013318>,
             <http://www.worldcat.org/oclc/037671494>,
             <http://www.worldcat.org/oclc/751661734>,
             <http://www.worldcat.org/oclc/800600611> .

- In addition, when the option to resolve OCLC works is enabled (OCLC_AUTH2WORKS option), the
  following triples were added to those above.

          <http://www.worldcat.org/oclc/004933024> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/796991413> .
          <http://www.worldcat.org/oclc/006626542> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/111527266> .
          <http://www.worldcat.org/oclc/007170722> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/144285064> .
          <http://www.worldcat.org/oclc/013525674> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/7358848> .
          <http://www.worldcat.org/oclc/013525712> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/7360091> .
          <http://www.worldcat.org/oclc/013700764> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/366036025> .
          <http://www.worldcat.org/oclc/013700768> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/366036042> .
          <http://www.worldcat.org/oclc/017649403> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/866252320> .
          <http://www.worldcat.org/oclc/018292079> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/836712068> .
          <http://www.worldcat.org/oclc/018380395> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/365996343> .
          <http://www.worldcat.org/oclc/023969230> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/890420837> .
          <http://www.worldcat.org/oclc/035911289> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/355875201> .
          <http://www.worldcat.org/oclc/036387153> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/622568> .
          <http://www.worldcat.org/oclc/037671494> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/9216290> .
          <http://www.worldcat.org/oclc/050868185> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/366714531> .
          <http://www.worldcat.org/oclc/495781917> schema:contributor <http://www.worldcat.org/identities/lccn-n79044798>;
             schema:exampleOfWork <http://www.worldcat.org/entity/work/id/994448191> .
          <http://www.worldcat.org/oclc/727657045> schema:contributor <http://www.worldcat.org/identities/lccn-n79044798>;
             schema:exampleOfWork <http://www.worldcat.org/entity/work/id/1811109792> .
          <http://www.worldcat.org/oclc/747413718> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/994448191> .
          <http://www.worldcat.org/oclc/751661734> schema:contributor <http://www.worldcat.org/identities/lccn-n79044798>;
             schema:exampleOfWork <http://www.worldcat.org/entity/work/id/1816359357> .
          <http://www.worldcat.org/oclc/782013318> schema:contributor <http://www.worldcat.org/identities/lccn-n79044798>;
             schema:exampleOfWork <http://www.worldcat.org/entity/work/id/146829946> .
          <http://www.worldcat.org/oclc/889440750> schema:exampleOfWork <http://www.worldcat.org/entity/work/id/2061462527> .


Ruby Library Use

- iterating records in an authority file

        require 'marc2linkeddata'
        marc_filename = 'auth.mrc'
        marc_file = File.open(marc_filename,'r')
        until marc_file.eof?
          leader = ParseMarcAuthority::parse_leader(marc_file)
          if leader[:type] == 'z'
            raw = marc_file.read(leader[:length])
            record = MARC::Reader.decode(raw)
            auth = ParseMarcAuthority.new(record)
            auth_id = "auth:#{auth.get_id}"
            graph = auth.graph
            puts graph.to_ttl
          end
        end

Development

    git clone https://github.com/ld4l/marc2linkeddata.git
    cd marc2linkeddata
    ./bin/setup.sh
    ./bin/test.sh
    cp .env_example .env # and edit .env
    # develop code and/or bin scripts; run bin scripts, e.g.
    .binstubs/marcAuthority2LD auth.mrc
    # Look for results in auth_turtle/*.ttl files.
    # see also full example script in
    #.binstubs/run_test_data.sh
    # which includes shell script for basic stats and
    # using rapper to check the file output syntax.


# License

Copyright 2014 The Board of Trustees of the Leland Stanford Junior University.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


# Redis

On Ubuntu, check the system redis is installed and running:

    sudo apt-get install redis-server redis-tools redis-desktop-manager
    service redis-server status
    # If necessary:
    #sudo service redis-server start
    #sudo service redis-server restart

Useful during development (use at your own risk):

    redis-cli 'FLUSHALL'

# 4store

 - http://4store.org/
 - http://4store.org/trac/wiki/Documentation

On Ubuntu, check the system 4store is installed and running:

    # installation
    sudo apt-get install 4store lib4store-dev lib4store0
    # that should install dependencies, such as:
    #sudo apt-get install libpcre3-dev
    #sudo apt-get install libraptor2-dev libraptor2-doc raptor2-utils
    #sudo apt-get install librasqal3-dev rasqal-utils
    # service admin
    sudo service 4store status
    # If necessary:
    #sudo service 4store start
    #sudo service 4store restart

Build from source

    # assuming 64-bit linux OS (e.g. Ubuntu)
    # install dependencies, e.g.
    sudo apt-get install libavahi-common3 libavahi-client3
    sudo apt-get install libraptor2-dev libraptor2-doc raptor2-utils
    sudo apt-get install librasqal3-dev librasqal3-doc rasqal-utils
    sudo apt-get install libpcre3-dev
    git clone https://github.com/garlik/4store.git
    cd 4store
    more docs/INSTALL  # out-dated, but read it anyway
    # also read http://4store.org/trac/wiki/Install
    sh autogen.sh
    ./configure
    make
    sudo make install  # installs binaries to /usr/local/bin/4s-*
    # optional:
    #make test

/etc/4store.conf should contain:

    [4s-boss]
          discovery = default
    [ld4l]
          port = 9000
          unsafe = true

Run 4s-boss:

    #4s-boss -D # debug mode to verify it works OK
    # kill the process with CNT-C
    4s-boss

When 4s-boss is running, 4s-admin can interact with it.

    4s-admin --help
    4s-admin list-nodes
    4s-admin list-stores
    # See other 4s-* utils, like 4s-size
    4s-size ld4l

Create and start a KB store:

    touch /var/log/4store/query-ld4l.log
    4s-admin create-store ld4l
    4s-admin start-stores ld4l

See 4store wiki for additional notes on creating databases at
 - http://4store.org/trac/wiki/Documentation
 - http://4store.org/trac/wiki/CreateDatabase

## Useful Development Commands

Preliminaries:

    # First shutdown the system 4store service
    sudo service 4store status
    sudo service 4store stop
    # Optional - switch to manual control of 4store service
    #sudo echo "manual" > /etc/init/4store.override
    # Start 4s-boss
    4s-boss

Routine commands (use at your own risk):

    4s-admin stop-stores ld4l && 4s-admin delete-stores ld4l
    4s-admin create-store ld4l && 4s-admin start-stores ld4l
    4s-httpd -D -R -s-1 ld4l
    # 4s-httpd locks out other processes, like 4s-size.
    # 4s-httpd options are read from /etc/4store.conf, plus:
    # -D = debug info
    # -R = reasoning (query rewriting)
    # -s -1 = no timeouts

## Loading Data from the Library of Congress (LOC)

- Download the LOC data

        cd $YOUR_DOWNLOAD_PATH
        # when the marc2linkeddata gem is installed,
        # this script should be available in the path.
        # The download could take a long time.
        loc_downloads.sh

- Add to /etc/4store.conf:

        [loc]
              port = 9001
              unsafe = true

- Create a new KB for the LOC data

        sudo service 4store stop
        touch /var/log/4store/query-loc.log
        4s-boss
        4s-admin create-store loc
        4s-admin start-stores loc
        4s-admin list-stores

- Import the LOC data into 4store

        cd $YOUR_DOWNLOAD_PATH
        # when the marc2linkeddata gem is installed,
        # this script should be available in the path.
        # The import could take a long time.
        loc_4store_import.sh

- Run the 4s-httpd server for the LOC KB

        4s-httpd -D -R -s-1 loc
        # 4s-httpd locks out other processes, like 4s-size.
        # 4s-httpd options are read from /etc/4store.conf, plus:
        # -D = debug info
        # -R = reasoning (query rewriting)
        # -s -1 = no timeouts

- Configure marc2linkeddata to use this KB

        # TODO, but it should result in something like this:
        # repo = RDF::FourStore::Repository.new('http://localhost:9001')





