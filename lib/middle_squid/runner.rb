module MiddleSquid
  class Runner
    include Actions
    include Helpers

    attr_reader :server

    def initialize(builder)
      raise Error, 'MiddleSquid is not initialized. Did you call Builder#run in your configuration file?' unless builder.handler

      define_singleton_method :_handler, builder.handler

      adapter = builder.adapter
      adapter.handler = proc {|*args| _handler *args }

      @custom_actions = builder.custom_actions

      @server = Server.new

      EM.run {
        adapter.start
        @server.start
      }
    end

    # @see Builder#define_action
    def method_missing(name, *args)
      custom_action = @custom_actions[name]
      super unless custom_action

      custom_action.call *args
    end
  end
end
