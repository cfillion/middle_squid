module MiddleSquid
  # Base class for MiddleSquid's adapters.
  # Subclasses should call {#handle} when they have received and parsed a request.
  #
  # @abstract Subclass and override {#output} to implement a custom adapter.
  class Adapter
    # Returns whatever was passed to {Builder#run}.
    #
    # @return [#call]
    attr_accessor :handler

    # Returns a new instance of Adapter.
    # Use {Builder#use} instead.
    def initialize(options = {})
      @options = options
    end

    # Execute the user handler (see {#handler}) and calls +#output+.
    #
    # @param url <String> string representation of the url to be processed
    # @param extras <Array> extra data to pass to the user's handler
    def handle(url, extras = [])
      uri = MiddleSquid::URI.parse url
      raise InvalidURIError, "invalid URL received: '#{url}'" if !uri || !uri.host

      action, options = catch :action do
        @handler.call uri, extras
        throw :action, [:accept, {}]
      end

      output action, options
    end

    # Pass an action to an underlying software.
    #
    # accept::
    #   (no options)
    #
    # redirect::
    #   Options:
    #   - +status+ [+Fixnum+]
    #   - +url+ [+String+]
    #
    # replace::
    #   Options:
    #   - +url+ [+String+]
    #
    # @param action [Symbol]
    # @param options [Hash]
    def output(action, options)
      raise NotImplementedError
    end
  end
end
