module MiddleSquid::Handlers
  class Input < EventMachine::Connection
    def initialize(callback)
      @buffer = []
      @callback = callback

      super
    end

    def receive_data(char)
      case char
      when "\x00"
        EM.stop
      when "\n"
        receive_line @buffer.join
        @buffer.clear
      else
        @buffer << char
      end
    end

    def receive_line(line)
      # EventMachine sends ASCII-8BIT strings, somehow preventing the databases queries to match
      reply = @callback.call line.force_encoding(Encoding::UTF_8)

      if reply
        puts reply
        STDOUT.flush
      end
    end
  end

  class HTTP < Thin::Backends::TcpServer
    attr_reader :signature

    def initialize(host, port, options)
      super host, port
    end
  end
end
