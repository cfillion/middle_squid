module MiddleSquid::Helpers
  #
  # @!group Predefined Helpers
  #

  # Download a resource with the same the headers and body as a rack request.
  #
  # @note
  #   Must be called inside an active fiber if used outside of {Actions#intercept}.
  # @example Transparent Proxying
  #   run proc {|uri, extras|
  #     # you should use 'accept' instead of doing this
  #     intercept {|req, res|
  #       download_like req, uri
  #     }
  #   }
  # @example Body Modification
  #   run proc {|uri, extras|
  #     intercept {|req, res|
  #       status, headers, body = download_like req, uri
  #       body.gsub! 'green', 'blue'
  #
  #       [status, headers, body]
  #     }
  #   }
  # @example Error Handling
  #   run proc {|uri, extras|
  #     intercept {|req, res|
  #       status, headers, body = download_like req, uri
  #
  #       if status == 200
  #         # ...
  #       else
  #         [500, {}, "Got an error: #{status}"]
  #       end
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

    sanitize_headers! headers

    options = {
      :head => headers,
      :body => request.body.read,
    }

    http = EM::HttpRequest.new(uri.to_s).send method, options
    http.callback {
      status = http.response_header.status
      headers = http.response_header
      body = http.response

      sanitize_headers! headers

      fiber.resume [status, headers, body]
    }
    http.errback { fiber.resume http.error }

    Fiber.yield
  end

  #
  # @!endgroup
  #

  # FIXME: should not be here. move to a new HTTP class
  private
  def sanitize_headers!(dirty)
    clean = {}
    dirty.each {|key, value|
      key = key.split('_').map(&:capitalize).join('-')
      next if MiddleSquid::IGNORED_HEADERS.include? key

      clean[key] = value
    }

    dirty.clear
    dirty.merge! clean
  end
end
