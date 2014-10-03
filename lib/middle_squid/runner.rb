module MiddleSquid
  class Runner
    include Actions
    include Helpers

    def initialize(builder)
      unless builder.handler
        warn '[MiddleSquid] ERROR: Invalid configuration: #run was not called.'
        return
      end

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
