require 'simplecov'

SimpleCov.start {
  project_name 'MiddleSquid'
  add_filter '/test/'
}

require 'rack/test'
require 'thin/async/test'
require 'minitest/autorun'

require 'middle_squid'

MiddleSquid::Config.database = ':memory:'
