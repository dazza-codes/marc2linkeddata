# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'marc2linkeddata'
  s.version     = '0.1.0'
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

  s.add_dependency 'addressable'
  s.add_dependency 'linkeddata'
  s.add_dependency 'marc'
  s.add_dependency 'restclient'
  s.add_dependency 'ruby-progressbar'

  # DB clients
  s.add_dependency 'mysql'  # not for jruby
  s.add_dependency 'sequel'

  # Use ENV for config
  s.add_dependency 'dotenv'

  # ruby gem for RDF on 4store, see https://github.com/emk/rdf-4store
  s.add_dependency 'rdf-4store'
  # ruby gem for RDF on allegrograph, see https://github.com/emk/rdf-agraph
  s.add_dependency 'rdf-agraph'
  # ruby gem for RDF on mongodb, see https://rubygems.org/gems/rdf-mongo
  s.add_dependency 'bson_ext'  # not for jruby
  s.add_dependency 'rdf-mongo'

  # cache simple RDF on redis
  s.add_dependency 'hiredis'
  s.add_dependency 'redis'

  # Use pry for console and debug config
  s.add_dependency 'pry'
  s.add_dependency 'pry-doc'
  s.add_development_dependency 'rspec'

  s.files   = `git ls-files`.split($/)
  dev_files = %w(.gitignore bin/setup.sh bin/test.sh)
  dev_files.each {|f| s.files.delete f }

  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
end
