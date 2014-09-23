class MiddleSquid
  Error = Class.new RuntimeError

  class Action < Exception
    attr_reader :line

    def initialize(line)
      @line = line
    end
  end

  InvalidURI = Class.new Exception
end
