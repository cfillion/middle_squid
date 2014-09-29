class MiddleSquid
  Error = Class.new RuntimeError

  # Use {Actions#action Actions#action} to raise this exception.
  class Action < Exception
    # @return [String]
    attr_reader :line

    # @param line [String]
    # @see MiddleSquid#action
    def initialize(line)
      @line = line
    end
  end

  InvalidURI = Class.new Exception
end
