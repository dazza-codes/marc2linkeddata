#!/usr/bin/env bash

set -e

#.binstubs/rspec
#.binstubs/cucumber --strict

bundle exec ruby ./lib/marc2linkeddata/loc.rb
bundle exec ruby ./lib/marc2linkeddata/viaf.rb

