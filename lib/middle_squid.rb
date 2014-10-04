require 'middle_squid/version'

require 'fiber'
require 'pathname'
require 'securerandom'

require 'addressable/uri'
require 'eventmachine'
require 'em-http-request'
require 'sqlite3'
require 'thin'
require 'thin/async'
require 'thor'

# Copyright (C) 2014 by Christian Fillion
#
# @see Builder Configuration syntax (DSL)
# @see Actions List of predefined actions
# @see Helpers List of predefined helpers
# @see Adapters Available adapters
module MiddleSquid
  require 'middle_squid/actions'
  require 'middle_squid/database'
  require 'middle_squid/helpers'

  module Adapters
    require 'middle_squid/adapter'
    require 'middle_squid/adapters/squid'
  end

  module Backends
    require 'middle_squid/backends/keyboard'
    require 'middle_squid/backends/thin'
  end

  require 'middle_squid/blacklist'
  require 'middle_squid/builder'
  require 'middle_squid/cli'
  require 'middle_squid/exceptions'
  require 'middle_squid/indexer'
  require 'middle_squid/runner'
  require 'middle_squid/server'
  require 'middle_squid/uri'

  require 'middle_squid/core_ext/hash'
end
