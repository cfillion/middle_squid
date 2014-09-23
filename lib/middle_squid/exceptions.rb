class MiddleSquid
  Error = Class.new RuntimeError

  class Action < Exception
    attr_reader :line

    def initialize(line)
      @line = line
    end
  end
end
