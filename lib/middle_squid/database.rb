module MiddleSquid::Database
  @@db = nil

  def self.setup
    return if @@db

    @@db = SQLite3::Database.new MiddleSquid::Config.database

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

  def self.build(*directories)
    start_time = Time.now
    indexed_cats = []

    used_cats = MiddleSquid::BlackList.instances.map {|bl| bl.category }
    used_cats.uniq!

    if used_cats.empty? && MiddleSquid::Config.minimal_indexing
      warn 'ERROR: the loaded configuration does not use any blacklist'
      puts 'nothing to do in minimal indexing mode'
      return
    end

    total = {
      :url    => 0,
      :domain  => 0,
      :ignored  => 0,
      :duplicate => 0,
    }

    setup
    @@db.transaction

    puts "truncating database"
    @@db.execute 'DELETE FROM domains' 
    @@db.execute 'DELETE FROM urls' 

    directories.each {|directory|
      puts "reading #{directory}"

      unless File.directory? directory
        warn "WARNING: #{directory}: no such directory"
        next
      end

      Dir.glob File.join(directory, '*/*') do |file|
        pn = Pathname.new file
        next unless pn.file?

        category = pn.dirname.basename.to_s

        if MiddleSquid::Config.minimal_indexing
          next unless used_cats.include? category
        end

        indexed_cats << category

        puts "indexing #{category}/#{pn.basename}"

        File.foreach(file) { |line|
          type = append_to category, line
          total[type] += 1
        }
      end
    }

    if total[:domain] > 0 || total[:url] > 0
      puts 'committing changes'
      @@db.commit
    else
      warn 'WARNING: nothing to commit'
      puts 'reverting changes'
      @@db.rollback
    end

    indexed_cats.uniq!
    missing_cats = used_cats - indexed_cats

    puts
    puts "indexed #{indexed_cats.size} categorie(s): #{indexed_cats}"
    warn "WARNING: could not find #{missing_cats}" unless missing_cats.empty?

    puts "found #{total[:domain]} domain(s)"
    puts "found #{total[:url]} url(s)"
    puts "found #{total[:duplicate]} duplicate(s)"
    puts "found #{total[:ignored]} ignored expression(s)"
    puts

    end_time = Time.now
    puts "finished after #{end_time - start_time} seconds"
  end

  def self.append_to(category, line)
    return :ignored unless line[0] =~ /\w/

    line.encode! Encoding::UTF_8,
      invalid: :replace, undef: :replace, replace: ''

    line.tr! '\\', '/'

    uri = Addressable::URI.parse "http://#{line}"
    host, path = uri.cleanhost, uri.cleanpath

    if path.empty?
      @@db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
        [category, host]
      :domain
    else
      @@db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
        [category, host, path]
      :url
    end
  rescue SQLite3::ConstraintException
    :duplicate
  end

  private
  def db
    MiddleSquid::Database.setup
    @@db
  end
end
