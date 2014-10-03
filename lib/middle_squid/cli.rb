module MiddleSquid
  class CLI < Thor
    class_option :'config-file',
      :required => true,
      :desc     => 'configuration file',
      :aliases  => ['-C']

    default_task :exec
    desc 'exec', 'start the squid helper (default)'
    def exec
      config_file = File.expand_path options[:'config-file']

      builder = Builder.from_file config_file
      MiddleSquid::Runner.new builder
    end

    desc 'build SOURCES...', 'populate the database from one or more blacklists'
    def build(*directories)
      config_file = File.expand_path options[:'config-file']
      directories.map! {|rel| File.expand_path rel }

      builder = Builder.from_file config_file

      MiddleSquid::Database.build *directories
    end

    desc 'version', 'show version and copyright'
    option :'config-file', :required => false, :aliases => ['-C']
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

    desc 'help', 'show this message or describe a command'
    option :'config-file', :required => false, :aliases => ['-C']
    def help; super; end
  end
end
