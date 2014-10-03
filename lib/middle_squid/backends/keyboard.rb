module MiddleSquid::Backends
  class Keyboard < EventMachine::Connection
    def initialize(handler)
      @buffer = []
      @handler = handler
    end

    def receive_data(char)
      case char
      when "\x00"
        EM.stop
      when "\n"
        line = @buffer.join
        @buffer.clear

        receive_line line
      else
        @buffer << char
      end
    end

    def receive_line(line)
      # EventMachine sends ASCII-8BIT strings, somehow preventing the databases queries to match
      @handler.call line.force_encoding(Encoding::UTF_8)
    end
  end
end
