# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'marc2linkeddata'
  s.version     = '0.2.1'
  s.licenses    = ['Apache-2.0']

  # mysql and bson_ext only install on MRI (c-ruby)
  s.platform    = Gem::Platform::RUBY

  s.authors     = ['Darren Weber',]
  s.email       = ['dlweber@stanford.edu']
  s.summary     = 'Convert Marc21 records to linked data, for use in SUL/DLSS projects'
  s.description = 'Utilities for translation of Marc21 records to linked open data.'
  s.homepage    = 'https://github.com/darrenleeweber/marc2linkeddata'

  #s.required_rubygems_version = '>= 1.3.6'
  # s.required_ruby_version = '>= 2.1.0'

  s.add_dependency 'addressable', '~> 2.3'
  s.add_dependency 'linkeddata', '~> 1.0'
  s.add_dependency 'marc', '~> 1.0'
  s.add_dependency 'nokogiri', '~> 1.6'
  s.add_dependency 'parallel', '~> 1.0'
  s.add_dependency 'rest-client', '~> 1.0'
  s.add_dependency 'ruby-progressbar', '~> 1.0'

  # DB clients
  s.add_dependency 'mysql', '~> 2.0'  # not for jruby
  s.add_dependency 'sequel', '~> 4.0'

  # Use ENV for config
  s.add_dependency 'dotenv', '~> 1.0'

  # ruby gem for RDF on 4store, see https://github.com/emk/rdf-4store
  s.add_dependency 'rdf-4store'
  # ruby gem for RDF on allegrograph, see https://github.com/emk/rdf-agraph
  s.add_dependency 'rdf-agraph'
  # ruby gem for RDF on mongodb, see https://rubygems.org/gems/rdf-mongo
  s.add_dependency 'bson_ext', '~> 1.0'  # not for jruby
  s.add_dependency 'rdf-mongo', '~> 1.0'

  # cache simple RDF on redis
  s.add_dependency 'hiredis'
  s.add_dependency 'redis', '~> 3.0'

  # Use pry for console and debug config
  s.add_dependency 'pry'
  s.add_dependency 'pry-doc'

  # Development dependencies
  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-ctags-bundler'

  s.files   = `git ls-files`.split($/)
  dev_files = %w(.gitignore bin/setup.sh bin/ctags.rb bin/test.sh)
  dev_files.each {|f| s.files.delete f }

  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
end
