module MiddleSquid::Config
  @blacklist_db = 'blacklist.db'

  class << self
    attr_accessor :blacklist_db
  end
end
