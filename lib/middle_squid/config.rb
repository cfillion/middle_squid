# Stores all MiddleSquid settings.
#
# @see MiddleSquid#config MiddleSquid#config
module MiddleSquid::Config
  @index_entries = [:domain, :url]
  @minimal_indexing = true

  class << self
    # Limits what to index in the blacklist database.
    # The supported values are:
    # - <code>:domain</code> --- Match host names. Eg. rubydoc.info, 127.0.0.1
    # - <code>:url</code> --- Match paths (query strings are ignored). Eg. github.com/cfillion, 127.0.0.1/file.html
    #
    # @return [Array<Symbol>] defaults to <code>[:domain, :url]</code>.
    # @see BlackList
    attr_accessor :index_entries

    # Whether to index only the blacklist categories used in the configuration script.
    # This provides a huge speed boost when running <code>middle_squid build</code>.
    #
    # Disable if you want to reuse the same database in multiple configurations
    # set to use different blacklist categories and you need to index everything.
    #
    # @return [Boolean] defaults to <code>true</code>.
    attr_accessor :minimal_indexing
  end
end
