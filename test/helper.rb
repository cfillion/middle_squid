require 'simplecov'

SimpleCov.start {
  project_name 'MiddleSquid'
  add_filter '/test/'
}

require 'minitest/autorun'
require 'rack/test'
require 'thin/async/test'
require 'webmock/minitest'

require 'middle_squid'

MiddleSquid::Config.database = ':memory:'
