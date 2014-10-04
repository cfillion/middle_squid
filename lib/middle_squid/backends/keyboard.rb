module MiddleSquid::Backends
  # Receives data from the standard input.
  class Keyboard < EventMachine::Connection
    # @param handler [#call] called when a full line has been received
    def initialize(handler)
      @buffer = []
      @handler = handler
    end

    # @param char [String] single character
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

    # @param line [String] full line without the trailing linebreak
    def receive_line(line)
      # EventMachine sends ASCII-8BIT strings, somehow preventing the databases queries to match
      @handler.call line.force_encoding(Encoding::UTF_8)
    end
  end
end
