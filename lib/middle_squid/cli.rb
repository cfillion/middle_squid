module MiddleSquid
  class CLI < Thor
    package_name 'MiddleSquid'

    class_option :'config-file',
      aliases:  '-C',
      default: '~/middle_squid.rb',
      desc:     'configuration file'

    # <START>
    desc 'start', 'run the given configuration file'

    # Runs the given configuration file.
    #
    # @example
    #   middle_squid start -C middle_squid_config.rb
    def start
      config_file = File.expand_path options[:'config-file']

      builder = Builder.from_file config_file

      MiddleSquid::Runner.new builder
    end
    # </START>

    # <INDEX>
    option :append,  type: :boolean, default: false, aliases: '-a',
      desc: 'keep the entries already in the database'

    option :domains, type: :boolean, default: true,
      desc: 'index domain lists'

    option :full,    type: :boolean, default: false,
      desc: 'index all blacklist categories'

    option :quiet,   type: :boolean, default: false, aliases: '-q',
      desc: 'disable status output'

    option :urls,    type: :boolean, default: true,
      desc: 'index urls lists'

    desc 'index SOURCES...', 'populate the database from one or more blacklists'

    # Populates the database from one or more blacklists
    #
    # *Flags:*
    #
    # [\-a, \--append, \--no-append]
    #   Whether to keep the entries already in the database.
    #
    # [\--domains, \--no-domains]
    #   Whether to index domain lists.
    #
    #   <b>Enabled by default.</b>
    #
    # [\--full, \--no-full]
    #   Whether to index all blacklist categories.
    #   By default MiddleSquid will only read the categories registered
    #   using {Builder#blacklist} in the configuration script.
    #
    #   Enable if you want to reuse the same database in multiple configurations
    #   set to use different blacklist categories and you need to index everything.
    #
    # [\-q, \--quiet, \--no-quiet]
    #   Whether to disable status output.
    #
    # [\--urls, \--no-urls]
    #   Whether to index url lists.
    #
    #   <b>Enabled by default.</b>
    #
    # @note {Builder#database} must be called in your configuration script in order to initialize the database.
    # @example
    #   middle_squid index ShallaBlackList -C middle_squid_config.rb
    def index(*directories)
      config_file = File.expand_path options[:'config-file']
      directories.map! {|rel| File.expand_path rel }

      builder = Builder.from_file config_file

      entries = []
      entries << :url if options[:urls]
      entries << :domain if options[:domains]

      indexer = MiddleSquid::Indexer.new
      indexer.blacklists = builder.blacklists

      indexer.append     = options[:append]
      indexer.entries    = entries
      indexer.full_index = options[:full]
      indexer.quiet      = options[:quiet]

      indexer.index directories
    end
    # </INDEX>

    # <VERSION>
    desc 'version', 'show version and copyright'
    def version
      puts "MiddleSquid #{MiddleSquid::VERSION}"
      puts <<GPL
Copyright (C) 2014 by Christian Fillion

  This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.
GPL
    end
    # </VERSION>
  end
end
