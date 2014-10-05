require 'simplecov'
require 'coveralls'

Coveralls::Output.silent = true

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start {
  project_name 'MiddleSquid'
  add_filter '/test/'

  add_group 'Adapters', '/adapter'
  add_group 'Backends', '/backend'
}

require 'minitest/autorun'
require 'rack/test'
require 'thin/async/test'
require 'webmock/minitest'

require 'middle_squid'

MiddleSquid::Database.setup ':memory:'
