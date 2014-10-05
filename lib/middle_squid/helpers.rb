module MiddleSquid::Helpers
  #
  # @!group Predefined Helpers
  #

  # Download a resource with the same headers and body as a rack request.
  #
  # @note
  #   This method must be called inside an active fiber. {Actions#intercept} does it automatically.
  # @example Transparent Proxying
  #   run lambda {|uri, extras|
  #     # you should use 'accept' instead of doing this
  #     intercept {|req, res|
  #       download_like req, uri
  #     }
  #   }
  # @example Body Modification
  #   run lambda {|uri, extras|
  #     intercept {|req, res|
  #       status, headers, body = download_like req, uri
  #
  #       content_type = headers['Content-Type'].to_s
  #
  #       if content_type.include? 'text/html'
  #         body.gsub! 'green', 'blue'
  #       end
  #
  #       [status, headers, body]
  #     }
  #   }
  # @param request [Rack::Request] the request to imitate
  # @param uri [URI] the resource to fetch
  # @return [Array] a rack triplet (status code, response headers and body)
  # @return [Object] error code or message
  # @see Actions#intercept
  def download_like(request, uri)
    fiber = Fiber.current

    method = request.request_method.downcase.to_sym

    headers = {'Content-Type' => request.env['CONTENT_TYPE']}
    request.env.
      select {|k| k.start_with? 'HTTP_' }.
      each {|key, val| headers[key[5..-1]] = val }

    headers.sanitize_headers!

    options = {
      :head => headers,
      :body => request.body.read,
    }

    http = EM::HttpRequest.new(uri.to_s).send method, options

    http.callback {
      status = http.response_header.status
      headers = http.response_header
      body = http.response

      headers.sanitize_headers!

      fiber.resume [status, headers, body]
    }

    http.errback {
      fiber.resume [520, {}, "[MiddleSquid] #{http.error}"]
    }

    Fiber.yield
  end

  #
  # @!endgroup
  #
end
