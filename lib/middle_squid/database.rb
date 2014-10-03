module MiddleSquid::Database
  @@db = nil

  def self.setup(path)
    @@db.close if @@db

    @@db = SQLite3::Database.new path

    @@db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS domains (
      category TEXT, host TEXT
    )
    SQL

    @@db.execute <<-SQL
    CREATE UNIQUE INDEX IF NOT EXISTS unique_domains ON domains (
      category, host
    )
    SQL

    @@db.execute <<-SQL
    CREATE TABLE IF NOT EXISTS urls (
      category TEXT, host TEXT, path TEXT
    )
    SQL

    @@db.execute <<-SQL
    CREATE UNIQUE INDEX IF NOT EXISTS unique_urls ON urls (
      category, host, path
    )
    SQL

    # minimize downtime due to locks when the database is rebuilding
    # see http://www.sqlite.org/wal.html
    @@db.execute 'PRAGMA journal_mode=WAL'
  end

  def db
    raise "The database is not initialized. Did you call Builder#database in your configuration file?" unless @@db

    @@db
  end
end
