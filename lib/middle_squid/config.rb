module MiddleSquid::Config
  @concurrency = false
  @database = 'blacklist.db'
  @index_entries = [:domain, :url]
  @minimal_indexing = true

  class << self
    attr_accessor :concurrency
    attr_accessor :database
    attr_accessor :index_entries
    attr_accessor :minimal_indexing
  end
end
