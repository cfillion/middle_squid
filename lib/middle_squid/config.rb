module MiddleSquid::Config
  @concurrency = false
  @database = 'blacklist.db'
  @minimal_indexing = true

  class << self
    attr_accessor :concurrency
    attr_accessor :database
    attr_accessor :minimal_indexing
  end
end
