module MiddleSquid
  class Adapters::Squid < Adapter
    def start
      warn "[MiddleSquid] WARNING: STDOUT is a terminal. This command should be launched from squid." if STDOUT.tty?
      EM.open_keyboard Backends::Keyboard, method(:input)
    end

    def input(line)
      parts = line.split

      @chan_id = @options[:concurrency] ? parts.shift : nil
      url, *extras = parts

      handle url, extras
    end

    def output(action)
      line = @chan_id ? "#{@chan_id} #{action.line}" : action.line

      puts line
      STDOUT.flush
    end
  end
end
