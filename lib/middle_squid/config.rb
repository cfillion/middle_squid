module MiddleSquid::Config
  @database = 'blacklist.db'
  @minimal_indexing = true

  class << self
    attr_accessor :database
    attr_accessor :minimal_indexing
  end
end
