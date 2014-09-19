class MiddleSquid::BlackList
  @@db = nil

  def self.prepare_database!
    return if @@db

    @@db = SQLite3::Database.new MiddleSquid::Config.blacklist_db

    @@db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS domains (
      category TEXT,
      host TEXT
    )
    SQL

    @@db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS urls (
      category TEXT,
      host TEXT,
      path TEXT
    )
    SQL
  end

  def initialize(category, domains: true, urls: true)
    self.class.prepare_database!

    @category = category
    @search_domains = domains
    @search_urls = urls
  end

  def include_domain?(uri)
    return false unless @search_domains

    !!@@db.get_first_value(
      'SELECT 1 FROM domains WHERE category = ? AND host = ?',
      [@category, uri.cleanhost]
    )
  end

  def include_url?(uri)
    return false unless @search_urls

    !!@@db.get_first_value(
      "SELECT 1 FROM urls WHERE category = ? AND host = ? AND ? LIKE path || '%'",
      [@category, uri.cleanhost, uri.cleanpath]
    )
  end

  def include?(uri)
    include_domain?(uri) || include_url?(uri)
  end
end
