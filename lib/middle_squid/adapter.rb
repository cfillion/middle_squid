module MiddleSquid
  class Adapter
    attr_writer :handler

    def initialize(options = {})
      @options = options
    end

    def handle(url, extras)
      uri = MiddleSquid::URI.parse url
      raise InvalidURIError if !uri || !uri.host

      @handler.call uri, extras
      raise Action.new 'ERR'
    rescue Action => action
      output action
    rescue Addressable::URI::InvalidURIError
      warn "[MiddleSquid] invalid URL received: '#{url}'"
    end
  end
end
