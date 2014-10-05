module MiddleSquid::Actions
  #
  # @!group Predefined Actions
  #

  # Allow the request to pass through. This is the default action.
  #
  # @example Whitelist a domain
  #   run lambda {|uri, extras|
  #     accept if uri.host == 'github.com'
  #   }
  def accept
    action :accept
  end

  # Redirect the browser to another URL.
  #
  # @example Redirect google.com to duckduckgo.com
  #   run lambda {|uri, extras|
  #     redirect_to "http://duckduckgo.com/#{uri.request_uri}" if uri.host == 'google.com'
  #   }
  # @param url [String] the new url
  # @param status [Fixnum] HTTP status code (see http://tools.ietf.org/html/rfc7231#section-6.4)
  def redirect_to(url, status: 301)
    action :redirect, status: status, url: url
  end

  # Serve another page in place of the requested one.
  # Avoid in favor of {#redirect_to} when possible.
  #
  # @example Block Google advertisements
  #   run lambda {|uri, extras|
  #     redirect_to 'http://webserver.lan/blocked.html' if uri.host == 'ads.google.com'
  #   }
  # @param url [String] the substitute url
  def replace_by(url)
    action :replace, url: url
  end

  # Hijack the request and generate a dynamic reply.
  # This can be used to skip landing pages,
  # change the behaviour of a website depending on the browser's headers or to
  # generate an entire virtual website using your favorite Rack framework.
  #
  # The block is called inside a fiber.
  # If the return value is a Rack triplet, it will be sent to the browser.
  #
  # @note
  #   With great power comes great responsibility.
  #   Please respect the privacy of your users.
  # @example Hello World
  #   run lambda {|uri, extras|
  #     intercept {|req, res|
  #       [200, {}, 'Hello World']
  #     }
  #   }
  # @yieldparam req [Rack::Request] the browser request
  # @yieldparam res [Thin::AsyncResponse] the response to send back
  # @yieldreturn Rack triplet or anything else
  # @see Helpers#download_like
  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    token = server.token_for block

    replace_by "http://#{server.host}:#{server.port}/#{token}"
  end

  #
  # @!endgroup
  #

  private
  def action(name, options = {})
    throw :action, [name, options]
  end
end
