module MiddleSquid
  class Adapter
    attr_accessor :handler

    def initialize(options = {})
      @options = options
    end

    def handle(url, extras)
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
