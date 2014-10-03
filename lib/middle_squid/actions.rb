module MiddleSquid::Actions
  #
  # @!group Predefined Actions
  #

  # Send a custom reply to squid.
  # The line format is documented at http://wiki.squid-cache.org/Features/Redirectors.
  #
  # @note
  #   The channel ID will be automatically prepended if {Config.concurrency Config.concurrency} is enabled.
  # @param line [String]
  def action(line)
    raise MiddleSquid::Action.new(line)
  end

  # Allow the request to pass through. This is the default action.
  #
  # @example Whitelist a domain
  #   run proc {|uri, extras|
  #     accept if uri.host == 'github.com'
  #   }
  # @raise [Action]
  def accept
    action 'ERR'
  end

  # Make squid sad by ignoring his query.
  #
  # @note
  #   Don't call this method unless you really know what you are doing!
  # @raise [Action]
  def drop
    action nil
  end

  # Redirect the browser to another URL.
  #
  # @example Redirect google.com to duckduckgo.com
  #   run proc {|uri, extras|
  #     redirect_to "http://duckduckgo.com/#{uri.request_uri}" if uri.host == 'google.com'
  #   }
  # @param url [String] the new url
  # @param status [Fixnum] HTTP status code (see http://tools.ietf.org/html/rfc7231#section-6.4)
  # @raise [Action]
  def redirect_to(url, status: 301)
    action "OK status=#{status} url=#{URI.escape url}"
  end

  # Serve another page in place of the requested one.
  # Avoid in favor of {#redirect_to} when possible.
  #
  # @example Block google ads.
  #   run proc {|uri, extras|
  #     redirect_to 'http://webserver.lan/blocked.html' if uri.host == 'ads.google.com'
  #   }
  # @param url [String] the substitute url
  # @raise [Action]
  def replace_by(url)
    action "OK rewrite-url=#{URI.escape url}"
  end

  # Hijack the request and generate a dynamic reply.
  # This can be used to skip landing pages,
  # change the behaviour of a website depending on the browser's headers or to
  # generate an entire virtual website using your favorite Rack framework.
  #
  # The block is called inside a fiber, so you can easily perform asynchronous tasks.
  # If the return value is a Rack triplet, it will be sent to the browser.
  #
  # @note
  #   With great power comes great responsibility.
  #   Please respect the privacy of your users.
  # @example Hello World
  #   run proc {|uri, extras|
  #     intercept {|req, res|
  #       [200, {}, 'Hello World']
  #     }
  #   }
  # @yieldparam req [Rack::Request] the browser request
  # @yieldparam res [Thin::AsyncResponse] the response to send back
  # @yieldreturn Rack triplet or anything else
  # @raise [Action]
  # @see Helpers#download_like
  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    token = server.token_for block

    replace_by "http://#{server.host}:#{server.port}/#{token}"
  end

  #
  # @!endgroup
  #
end
