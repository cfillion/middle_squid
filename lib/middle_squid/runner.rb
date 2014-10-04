module MiddleSquid
  class Runner
    include Actions
    include Helpers

    attr_reader :server

    def initialize(builder)
      raise Error, 'Invalid handler. Did you call Builder#run in your configuration file?' unless builder.handler

      define_singleton_method :_handler, builder.handler

      builder.custom_actions.each {|name, body|
        define_singleton_method name, body
      }

      adapter = builder.adapter
      adapter.handler = proc {|*args| _handler *args }

      @server = Server.new

      EM.run {
        adapter.start
        @server.start
      }
    end
  end
end