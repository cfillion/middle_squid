class MiddleSquid
  Error = Class.new Exception

  class Action < Exception
    attr_reader :type, :params

    def initialize(type, params)
      @type, @params = type, params
    end
  end
end
