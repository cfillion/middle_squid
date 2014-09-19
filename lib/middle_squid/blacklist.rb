class MiddleSquid::BlackList
  def initialize(category, domains: true, urls: true)
    @category = category
  end

  def include?(uri)
    false
  end
end
