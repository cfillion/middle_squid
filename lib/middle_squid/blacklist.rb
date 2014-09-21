class MiddleSquid::BlackList
  include MiddleSquid::Database

  @@instances = []
  @@too_late = false

  def self.instances; @@instances; end
  def self.deadline!; @@too_late = true; end

  attr_reader :category

  def initialize(category)
    if @@too_late
      raise MiddleSquid::Error,
        'blacklists cannot be initialized inside the squid helper'
    end

    @category = category
    @@instances << self
  end

  def include_domain?(uri)
    !!db.get_first_value(
      'SELECT 1 FROM domains WHERE category = ? AND host = ? LIMIT 1',
      [@category, uri.cleanhost]
    )
  end

  def include_url?(uri)
    !!db.get_first_value(
      "SELECT 1 FROM urls WHERE category = ? AND host = ? AND ? LIKE path || '%' LIMIT 1",
      [@category, uri.cleanhost, uri.cleanpath]
    )
  end

  def include?(uri)
    include_domain?(uri) || include_url?(uri)
  end
end
