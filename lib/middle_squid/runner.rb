module MiddleSquid
  # Used internally to start the configured adapter and the internal HTTP server.
  # The handler passed to {Builder#run} will be called in this context.
  #
  # @see Builder Configuration DSL
  # @see CLI#start <code>middle_squid start</code> command
  class Runner
    include Actions
    include Helpers

    # Returns the internal HTTP server.
    #
    # @return [Server]
    attr_reader :server

    # @raise [Error] if the handler is undefined
    def initialize(builder)
      raise Error, 'Invalid handler. Did you call Builder#run in your configuration file?' unless builder.handler

      define_singleton_method :_handler_wrapper, builder.handler

      builder.custom_actions.each {|name, body|
        define_singleton_method name, body
      }

      adapter = builder.adapter
      adapter.handler = method :_handler_wrapper

      @server = Server.new

      EM.run {
        adapter.start
        @server.start
      }
    end
  end
end
