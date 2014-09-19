require 'simplecov'
require 'minitest/autorun'

SimpleCov.start {
  project_name 'MiddleSquid'
  add_filter '/test/'
}

require 'middle_squid'

MiddleSquid::Config.blacklist_db = ':memory:'
