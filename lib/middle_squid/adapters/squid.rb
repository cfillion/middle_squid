module MiddleSquid
  # @see http://wiki.squid-cache.org/Features/Redirectors
  class Adapters::Squid < Adapter
    def start
      warn "[MiddleSquid] WARNING: STDOUT is a terminal. This command should be launched from squid." if STDOUT.tty?

      EM.open_keyboard Backends::Keyboard, method(:input)
    end

    def input(line)
      parts = line.split

      @chan_id = @options[:concurrency] ? parts.shift : nil
      url, *extras = parts

      extras.map! {|str| URI.unescape str }

      handle url, extras
    end

    def output(action, options)
      case action
      when :accept
        reply 'ERR'
      when :redirect
        reply 'OK', status: options[:status], url: options[:url]
      when :replace
        reply 'OK', :'rewrite-url' => options[:url]
      else
        raise Error, "unsupported action: #{action}"
      end
    end

    private
    def reply(result, **kv_pairs)
      parts = []
      parts << @chan_id if @chan_id
      parts << result
      parts.concat kv_pairs.map {|k,v| "#{k}=#{URI.escape v.to_s}" }

      $stdout.puts parts.join("\x20")
      $stdout.flush
    end
  end
end
