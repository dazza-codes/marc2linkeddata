
marc2linkeddata
===============

Utilities for translating MARC21 into linked data.  The project has
focused on authority records (as of 2015).

It has config options that can be enabled to increase the amount of data retrieved.
Without any HTTP options enabled, using only data in the MARC record, it can
translate 100,000 authority records in about 5-6 min on a current laptop system.
File IO is the most expensive operation in this mode, so it helps to have a solid
state drive or something with high IO performance.

The current output is to the file system, but it should be easy to incorporate
and configure alternatives by using the RDF.rb facilities for connecting to a
repository.  A minor attempt was explored to use redis for caching, but that
exploration hasn't matured much, mainly because there is no 'cache-expiry' data
yet and because it would be better to use an RDF.rb extension of some
kind (for redis, mongodb, etc) or to use a triple store/solr platform.

With HTTP/RDF retrieval options enabled, it can take a lot longer (days) and the
providers may not be very happy about a barrage of requests.

Note that it runs a lot slower on jruby-9.0.0.0-pre1 than MRI 2.2.0, whether threads
are enabled or not.  It raises exceptions on jruby-1.7.9, related to ruby
language support (such as Array#delete_if).

TODO: A significant problem to solve is effective caching or mirrors for linked data.
The retrieval should inspect any HTTP cache headers that might be available and
adding PROVO to the linked-data graph generated for each record.

TODO: Provide system platform options, to dockerize the application and make it easier
for automatic horizontal scaling.  Consider https://www.packer.io/intro/index.html

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
    rbenv install 2.1.5   # or the latest ruby available
    rbenv global 2.1.5
    rbenv rehash
    gem install bundle
    gem install marc2linkeddata

Configure

    # set env values and/or create or modify a .env file
    # see the .env_example file for details
    marc2LD_config
    # Performance will slow with more retrieval of linked
    # data resources, such as OCLC works for authorities.

Scripting

    # First configure (see details above).
    # Translate a MARC21 authority file to a turtle file.
    # readMarcAuthority [ authfile1.mrc .. authfileN.mrc ]
    marcAuthority2LD auth.01.mrc

    # Check the syntax of the resulting turtle file.
    rapper -c -i turtle auth.01.ttl


Ruby Library Use

- authority files

        require 'marc2linkeddata'
        marc_filename = 'stf_auth.01.mrc'
        marc_file = File.open(marc_filename,'r')
        until marc_file.eof?
          leader = ParseMarcAuthority::parse_leader(marc_file)
          if leader[:type] == 'z'
            raw = marc_file.read(leader[:length])
            record = MARC::Reader.decode(raw)
            auth = ParseMarcAuthority.new(record)
            auth_id = "auth:#{auth.get_id}"
            triples = auth.to_ttl
          end
        end

Development

    git clone https://github.com/ld4l/marc2linkeddata.git
    cd marc2linkeddata
    ./bin/setup.sh
    ./bin/test.sh
    cp .env_example .env # and edit .env
    # develop code and/or bin scripts; run bin scripts, e.g.
    .binstubs/marcAuthority2LD auth.01.mrc


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





