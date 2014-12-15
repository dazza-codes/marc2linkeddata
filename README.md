
marc2linkeddata
===============

Utilities for translating MARC21 into linked data.

Install

    gem install marc2linkeddata

Require

    require 'marc2linkeddata'

Clone

    git clone git@github.com:darrenleeweber/marc2linkeddata.git


# 4store

 - http://4store.org/
 - http://4store.org/trac/wiki/Documentation

On Ubuntu, check the system-4store is installed and running:

    # installation
    sudo apt-get install 4store lib4store-dev lib4store0
    sudo apt-get install libpcre3 libpcre3-dev
    sudo apt-get install libraptor2-0 libraptor2-dev libraptor2-doc raptor2-utils
    sudo apt-get install librasqal3 librasqal3-dev rasqal-utils
    # service admin
    sudo service 4store status
    sudo service 4store start # or restart

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

## Useful development commands

Preliminaries:

    # First shutdown the system 4store service
    sudo service 4store status
    sudo service 4store stop
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
