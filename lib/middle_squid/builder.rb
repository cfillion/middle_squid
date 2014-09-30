module MiddleSquid
  class Builder
    include Actions
    include Helpers

    def initialize
      @run_was_called = false
      @server = Server.new
    end

    # Evalutate a configuration file.
    #
    # @api private
    def eval(file, inhibit_run: false)
      @inhibit_run = inhibit_run

      content = File.read file
      instance_eval content, file
    ensure
      @inhibit_run = false
    end

    # Whether {#run} was called.
    #
    # @api private
    def ran?
      @run_was_called
    end

    # Tweak MiddleSquid settings.
    # See {Config} for the list of available options.
    #
    # @example Default values
    #   config do |c|
    #     c.concurrency = false
    #     c.database = 'blacklist.db'
    #     c.index_entries = [:domain, :url]
    #     c.minimal_indexing = true
    #   end
    #
    #   # run proc {|uri, extras| ... }
    # @return [Config]
    def config
      yield Config if block_given?
      Config
    end

    # Start the squid helper and the internal server.
    #
    # Takes any object that responds to the call method with two arguments:
    # the uri to process and an array of extra data received from squid.
    #
    # @example
    #   run proc {|uri, extras|
    #     # called when a query from squid has been received
    #   }
    # @param callback [#call<URI, Array>]
    # @see http://www.squid-cache.org/Doc/config/url_rewrite_extras/
    def run(callback)
      return if @inhibit_run

      BlackList.deadline!

      @run_was_called = true

      EM.run {
        adapter = Adapters::Squid.new
        adapter.callback = callback

        @server.start
      }
    end
  end
end
