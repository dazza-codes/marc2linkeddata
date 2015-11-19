#!/usr/bin/env ruby
system "find ./lib/ -name '*.rb' | ctags -f .tags --languages=Ruby -L -"
system "find .gems/ -name '*.rb' | ctags -f .gemtags --languages=Ruby -L -"

# if File.exist? './Gemfile'
#   require 'bundler'
#   paths = Bundler.load.specs.map(&:full_gem_path).join(' ')
#   puts paths
#   system "ctags -R -f .gemtags --languages=Ruby #{paths}"
# end
