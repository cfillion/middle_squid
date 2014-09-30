module MiddleSquid::Backends
  class Keyboard < EventMachine::Connection
    def initialize(callback)
      @buffer = []
      @callback = callback
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
      @callback.call line.force_encoding(Encoding::UTF_8)
    end
  end
end
