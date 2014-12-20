
marc2linkeddata
===============

Utilities for translating MARC21 into linked data.

Optional Dependencies

  - http://redis.io/
  - http://4store.org/

Install

    gem install marc2linkeddata
    # when a gem is published

Use

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

Clone

    git clone git@github.com:darrenleeweber/marc2linkeddata.git
    cd marc2linkeddata
    ./bin/setup.sh
    ./bin/test.sh

Script

    # Translate a MARC21 authority file to a turtle file.
    # readMarcAuthority [ authfile1.mrc .. authfileN.mrc ]
    .binstubs/readMarcAuthority data/auth.01.mrc

    # Check the syntax of the resulting turtle file.
    rapper -c -i turtle data/auth.01.ttl

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
    sudo apt-get install libpcre3 libpcre3-dev
    sudo apt-get install libraptor2-0 libraptor2-dev libraptor2-doc raptor2-utils
    sudo apt-get install librasqal3 librasqal3-dev rasqal-utils
    # service admin
    sudo service 4store status
    # If necessary:
    #sudo service 4store start
    #sudo service 4store restart

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
