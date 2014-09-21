class MiddleSquid::CLI < Thor
  class_option :'config-file',
    :required => true,
    :desc     => 'configuration file',
    :aliases  => ['-C']

  default_task :exec
  desc 'exec', 'start the squid helper (default)'
  def exec
    warn "[MiddleSquid] WARNING: STDOUT is a terminal. This command should be launched from squid." if STDOUT.tty?

    ms = MiddleSquid.new
    ms.eval options[:'config-file']
  end

  desc 'build BLACKLIST', 'populate the blacklist database'
  def build(directory)
    ms = MiddleSquid.new
    ms.eval options[:'config-file'], inhibit_run: true

    MiddleSquid::Database.build directory
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
  def help
    super
  end
end
