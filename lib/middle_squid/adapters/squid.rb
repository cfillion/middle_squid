module MiddleSquid
  class Adapters::Squid < Adapter
    def initialize
      EM.open_keyboard Backends::Keyboard, method(:input)
    end

    def input(line)
      parts = line.split

      @chan_id = Config.concurrency ? parts.shift : nil
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
