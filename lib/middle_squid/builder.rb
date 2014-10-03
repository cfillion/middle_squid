module MiddleSquid
  class Builder
    attr_reader :adapter, :blacklists, :custom_actions, :handler

    def initialize
      @blacklists = []
      @custom_actions = {}
    end

    def self.from_file(file)
      obj = self.new
      content = File.read file

      obj.instance_eval content, file
      obj
    end

    def use(adapter, **options)
      raise ArgumentError, 'Not an adapter.' unless adapter < Adapter
      @adapter = adapter.new(options)
    end

    def adapter
      @adapter ||= Adapters::Squid.new
    end

    # Path to the blacklist database (SQLite).
    # The database will be created if the file does not exists.
    # Read/write access is required.
    #
    # @param path [String]
    def database(path)
      Database.setup path
    end

    def blacklist(*args)
      bl = BlackList.new *args
      @blacklists << bl
      bl
    end

    # Register a custom action (only in the current instance).
    #
    # @example Don't Repeat Yourself
    #   define_action :block do
    #     redirect_to 'http://goodsite.com/'
    #   end
    #
    #   run {|uri, extras|
    #     block if uri.host == 'badsite.com'
    #     # ...
    #     block if uri.host == 'terriblesite.com'
    #   }
    # @param name  [Symbol] method name
    # @param block [Proc]   method body
    def define_action(name, &block)
      raise ArgumentError, 'no block given' unless block_given?

      @custom_actions[name] = block
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
    def run(handler)
      raise ArgumentError, 'the handler must respond to #call' unless handler.respond_to? :call
      @handler = handler
    end
  end
end
