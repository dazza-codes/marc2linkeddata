#!/usr/bin/env bash

set -e

[[ -s .env ]] && mv .env .env_bak
cp .env_example .env

# The `|| echo ''` enables the bash script to continue after rspec failure
EXIT=0
.binstubs/rspec --color || EXIT=1
#.binstubs/cucumber --strict || EXIT=1

[[ -s .env_bak ]] && mv .env_bak .env
exit $EXIT

