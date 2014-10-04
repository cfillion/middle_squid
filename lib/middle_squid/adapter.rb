module MiddleSquid
  class Adapter
    attr_writer :handler

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
  end
end
