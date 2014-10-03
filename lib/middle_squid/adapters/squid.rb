# @see http://wiki.squid-cache.org/Features/Redirectors
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

    def output(action, options)
      line = @chan_id ? "#{@chan_id} " : ''

      line << \
      case action
      when :accept
        'ERR'
      when :redirect
        "OK status=#{options[:status]} url=#{URI.escape options[:url]}"
      when :replace
        "OK rewrite-url=#{URI.escape options[:url]}"
      else
        raise Error, "unsupported action: #{action}"
      end

      puts line
      STDOUT.flush
    end
  end
end
