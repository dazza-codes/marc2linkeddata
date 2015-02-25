#!/usr/bin/env bash

set -e

rm -f .binstubs/*
bundle install --binstubs .binstubs
bundle package --all --quiet

# see commentary on this practice at
# http://blog.howareyou.com/post/66375371138/ruby-apps-best-practices

./bin/ctags.rb
