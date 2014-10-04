module MiddleSquid
  class Indexer
    include Database
    
    attr_accessor :full_index, :entries, :append, :quiet

    def initialize
      @append = false
      @entries = [:url, :domain]
      @full_index = true
      @quiet = false

      @aliases = {}
      @cats_in_use  = []
      @indexed_cats = []

      @total = {
        :url    => 0,
        :domain  => 0,
        :ignored  => 0,
        :duplicate => 0,
      }
    end

    def blacklists=(list)
      @cats_in_use.clear
      @aliases.clear

      list.each {|bl|
        @cats_in_use << bl.category

        bl.aliases.each {|name|
          @aliases[name] = bl.category
        }
      }

      @cats_in_use.uniq!
    end

    def index(directories)
      if !@full_index && @cats_in_use.empty?
        warn 'ERROR: the loaded configuration does not use any blacklist'
        puts 'nothing to do in minimal indexing mode'
        return
      end

      start_time = Time.now

      db.transaction

      truncate unless @append
      directories.each {|dir|
        walk_in dir
      }
      cats_summary
      stats
      commit_or_rollback

      end_time = Time.now
      puts "finished after #{end_time - start_time} seconds"
    ensure
      db.rollback if db.transaction_active?
    end

    private
    def puts(*args)
      super *args unless @quiet
    end

    def truncate
      puts 'truncating database'

      db.execute 'DELETE FROM domains' 
      db.execute 'DELETE FROM urls' 
    end

    def walk_in(directory)
      puts "reading #{directory}"

      unless File.directory? directory
        warn "WARNING: #{directory}: no such directory"
        return
      end

      files = Dir.glob File.join(directory, '*/*')
      files.sort! # fixes travis build

      files.each {|file|
        index_file file
      }
    end

    def index_file(path)
      pn = Pathname.new path
      return unless pn.file?

      dirname = pn.dirname.basename.to_s
      category = @aliases.has_key?(dirname) \
        ? @aliases[dirname]
        : dirname

      if !@full_index
        return unless @cats_in_use.include? category
      end

      @indexed_cats << category

      puts "indexing #{dirname}/#{pn.basename}"

      File.foreach(path) {|line|
        type = append_to category, line
        @total[type] += 1
      }
    end

    def append_to(category, line)
      # remove trailing whitespace
      line.strip!

      # ignore regex lists
      return :ignored unless line[0] =~ /\w/

      # fix invalid bytes
      line.scrub! ''

      # fix for dirty lists
      line.tr! '\\', '/'

      uri = MiddleSquid::URI.parse "http://#{line}"
      host, path = uri.cleanhost, uri.cleanpath

      if path.empty?
        return :ignored unless @entries.include? :domain

        db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
          [category, host]

        :domain
      else
        return :ignored unless @entries.include? :url

        db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
          [category, host, path]

        :url
      end
    rescue SQLite3::ConstraintException
      :duplicate
    end

    def cats_summary
      @indexed_cats.uniq!
      missing_cats = @cats_in_use - @indexed_cats

      puts
      puts "indexed #{@indexed_cats.size} categorie(s): #{@indexed_cats}"
      warn "WARNING: could not find #{missing_cats}" unless missing_cats.empty?
    end

    def stats
      puts "found #{@total[:domain]} domain(s)"
      puts "found #{@total[:url]} url(s)"
      puts "found #{@total[:duplicate]} duplicate(s)"
      puts "found #{@total[:ignored]} ignored expression(s)"
      puts
    end

    def commit_or_rollback
      if @total[:domain] > 0 || @total[:url] > 0
        puts 'committing changes'
        db.commit
      else
        warn 'ERROR: nothing to commit'
        puts 'reverting changes'
        db.rollback
      end
    end
  end
end
