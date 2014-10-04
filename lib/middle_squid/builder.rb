module MiddleSquid
  # Small DSL to configure MiddleSquid.
  #
  # @example
  #   database '/home/proxy/blacklist.db'
  #
  #   adv     = blacklist 'adv', aliases: ['ads']
  #   tracker = blacklist 'tracker'
  #
  #   run lambda {|uri, extras|
  #     if adv.include? uri
  #       redirect_to 'http://your.webserver/block_pages/advertising.html'
  #     end
  #
  #     if tracker.include? uri
  #       redirect_to 'http://your.webserver/block_pages/tracker.html'
  #     end
  #   }
  class Builder
    # Returns the blacklists registered by {#blacklist}.
    #
    # @return [Array<BlackList>]
    attr_reader :blacklists

    # Returns the custom actions created by {#define_action}.
    #
    # @return [Hash<Symbol, Proc>]
    attr_reader :custom_actions

    # Returns the object passed to {#run}.
    #
    # @return [#call]
    attr_reader :handler

    # Returns the adapter selected by {#use}.
    #
    # @!attribute [r] adapter
    # @return [Adapter]
    def adapter
      @adapter ||= Adapters::Squid.new
    end

    def initialize
      @blacklists = []
      @custom_actions = {}
    end

    # @return [Builder]
    def self.from_file(file)
      obj = self.new
      content = File.read file

      obj.instance_eval content, file
      obj
    end

    # Select the active adapter.
    # By default {Adapters::Squid} with no options will be used.
    #
    # @example Squid in concurrency mode
    #   use Adapters::Squid, concurrency: true
    # @param adapter [Class]
    # @param options [Hash] adapter configuration
    # @return [Adapter]
    # @raise [ArgumentError] if +adapter+ is not a subclass of {Adapter}
    # @see Adapters List of predefined adapters
    def use(adapter, **options)
      raise ArgumentError, 'Not an adapter.' unless adapter < Adapter

      @adapter = adapter.new(options)
    end

    # Setup the blacklist database.
    # It will be created if the file does not exists.
    # Read/write access is required.
    #
    # Run {CLI#index middle_squid index} to add your blacklists to the database.
    #
    # @example
    #   database '/home/proxy/blacklist.db'
    #
    #   run lambda {|uri, extras| }
    # @param path [String] path to the SQLite database
    def database(path)
      Database.setup path
    end

    # Returns a new registered blacklist instance.
    #
    # @note You need to call {#database} in order to use the blacklists.
    # @example Block advertising
    #   adv = blacklist 'adv'
    #
    #   run lambda {|uri, extras|
    #     do_something if adv.include? uri
    #   }
    # @example Group blacklists
    #   adv = blacklist 'adv'
    #   tracker = blacklist 'tracker'
    #
    #   group = [adv, tracker]
    #
    #   run lambda {|uri, extras|
    #     do_something if group.any? {|bl| bl.include? uri }
    #   }
    # @example Create an alias
    #   adv = blacklist 'adv', aliases: ['ads']
    #
    #   run lambda {|uri, extras|
    #     do_something if adv.include? uri
    #   }
    # @return [BlackList]
    # @see BlackList#initialize BlackList#initialize
    def blacklist(*args)
      bl = BlackList.new *args
      @blacklists << bl
      bl
    end

    # Register a custom action or helper.
    #
    # @example Don't Repeat Yourself
    #   define_action :block do
    #     redirect_to 'http://goodsite.com/'
    #   end
    #
    #   run lambda {|uri, extras|
    #     block if uri.host == 'badsite.com'
    #     # ...
    #     block if uri.host == 'terriblesite.com'
    #   }
    # @param name  [Symbol] method name
    # @param block [Proc]   method body
    # @see Actions List of predefined actions
    # @see Helpers List of predefined helpers
    def define_action(name, &block)
      raise ArgumentError, 'no block given' unless block_given?

      @custom_actions[name] = block
    end

    # Takes any object that responds to the +call+ method with two arguments:
    # the uri to process and an array of extra data.
    #
    # @example
    #   run lambda {|uri, extras|
    #     # executed when the adapter has received a query from an underlying software (eg. Squid)
    #   }
    # @param handler [#call<URI, Array>]
    # @raise [ArgumentError] if +handler+ does not respond to +#call+
    # @see Runner Execution context (Runner)
    def run(handler)
      raise ArgumentError, 'the handler must respond to #call' unless handler.respond_to? :call

      @handler = handler
    end
  end
end
