module MiddleSquid
  # Used internally to build the blacklist database.
  #
  # @see CLI#index <code>middle_squid index</code> command
  class Indexer
    include Database
    
    # @return [Boolean]
    attr_accessor :append

    # @return [Array<Symbol>]
    attr_accessor :entries

    # @return [Boolean]
    attr_accessor :full_index

    # @return [Boolean]
    attr_accessor :quiet

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

    # @param list [Array<BlackList>]
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

    # @param directories [Array<String>]
    def index(directories)
      if !@full_index && @cats_in_use.empty?
        oops 'the loaded configuration does not use any blacklist'
        info 'nothing to do in minimal indexing mode'
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
      info "finished after #{end_time - start_time} seconds"
    ensure
      db.rollback if db.transaction_active?
    end

    private
    def output(string, always: false)
      $stderr.print string if always || !@quiet
    end

    def oops(msg)
      output "ERROR: #{msg}\n", always: true
    end

    def warn(msg)
      output "WARNING: #{msg}\n", always: true
    end

    def info(line = "")
      line << "\n"
      output line
    end

    def truncate
      info 'truncating database'

      db.execute 'DELETE FROM domains' 
      db.execute 'DELETE FROM urls' 
    end

    def walk_in(directory)
      info "reading #{directory}"

      unless File.directory? directory
        warn "#{directory}: no such directory"
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

      info "indexing #{dirname}/#{pn.basename}"

      File.foreach(path) {|line|
        type = append_to category, line
        @total[type] += 1
      }
    end

    def append_to(category, line)
      # fix invalid UTF-8 byte sequences
      line.scrub! ''

      # remove trailing whitespace
      line.strip!

      # ignore regex lists
      return :ignored unless line[0] =~ /\w/

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

      info
      info "indexed #{@indexed_cats.size} categorie(s): #{@indexed_cats}"
      warn "could not find #{missing_cats}" unless missing_cats.empty?
    end

    def stats
      info "found #{@total[:domain]} domain(s)"
      info "found #{@total[:url]} url(s)"
      info "found #{@total[:duplicate]} duplicate(s)"
      info "found #{@total[:ignored]} ignored expression(s)"
      info
    end

    def commit_or_rollback
      if @total[:domain] > 0 || @total[:url] > 0
        info 'committing changes'
        db.commit
      else
        oops 'nothing to commit'
        info 'reverting changes'
        db.rollback
      end
    end
  end
end
