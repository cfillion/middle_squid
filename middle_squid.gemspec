# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'middle_squid/version'

Gem::Specification.new do |spec|
  spec.name          = 'middle_squid'
  spec.version       = MiddleSquid::VERSION
  spec.authors       = ['cfi30']
  spec.email         = ['middle_squid@cfillion.tk']
  spec.summary       = 'A redirector, mangler and content replacement for squid'
  spec.homepage      = 'https://bitbucket.org/cfi30/middle_squid'
  spec.license       = 'GPL-3.0+'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'minitest', '~> 5.4'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_runtime_dependency 'addressable', '~> 2.3'
  spec.add_runtime_dependency 'eventmachine', '~> 1.0'
  spec.add_runtime_dependency 'sqlite3', '~> 1.3'
  spec.add_runtime_dependency 'thor', '~> 0.19'
end
