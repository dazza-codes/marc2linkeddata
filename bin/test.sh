#!/usr/bin/env bash

set -e

#.binstubs/rspec
#.binstubs/cucumber --strict

bundle exec ruby ./lib/loc.rb
bundle exec ruby ./lib/viaf.rb

