module MiddleSquid::Handlers
  class Input < EventMachine::Connection
    include EM::Protocols::LineText2

    def initialize(callback)
      @callback = callback
      super
    end

    def receive_line(line)
      # EventMachine sends ASCII-8BIT strings, somehow preventing the databases queries to match
      reply = @callback.call line.force_encoding(Encoding::UTF_8)
      puts reply if reply
    end
  end

  class HTTP < Thin::Backends::TcpServer
    attr_reader :signature

    def initialize(host, port, options)
      super host, port
    end
  end
end
