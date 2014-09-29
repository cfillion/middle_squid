class MiddleSquid
  PURGE_DELAY = 10
  SERVER_HOST = '127.0.0.1'.freeze
  IGNORED_HEADERS = [
    'Connection',
    'Content-Encoding',
    'Content-Length',
    'Host',
    'Transfer-Encoding',
    'Version',
  ].freeze

  # @return [String]
  attr_reader :server_host

  # @return [Fixnum]
  attr_reader :server_port

  def initialize
    @custom_actions = {}
    @tokens = {}
    @run_was_called = false
  end

  # Evalutate a configuration file.
  #
  # @api private
  def eval(file, inhibit_run: false)
    @inhibit_run = inhibit_run

    content = File.read file
    instance_eval content, file
  ensure
    @inhibit_run = false
  end

  # Whether {#run} was called.
  #
  # @api private
  def ran?
    @run_was_called
  end

  # Tweak MiddleSquid settings.
  # See {Config} for the list of available options.
  #
  # @example Default values
  #   config do |c|
  #     c.concurrency = false
  #     c.database = 'blacklist.db'
  #     c.index_entries = [:domain, :url]
  #     c.minimal_indexing = true
  #   end
  #
  #   # run proc {|uri, extras| ... }
  # @return [Config]
  def config
    yield Config if block_given?
    Config
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
  def run(callback)
    return if @inhibit_run

    BlackList.deadline!

    @run_was_called = true
    @user_callback = callback

    EM.run {
      EM.open_keyboard Handlers::Input, method(:squid_handler)

      Thin::Logging.logger = Logger.new STDERR
      Thin::Logging.level = Logger::WARN

      server = Thin::Server.new SERVER_HOST, 0, method(:http_handler),
        :backend => Handlers::HTTP,
        :signals => false

      server.start

      sockname = EM.get_sockname server.backend.signature
      @server_port, @server_host = Socket.unpack_sockaddr_in sockname
    }
  end

  #
  # @!group Actions
  #

  # Send a custom reply to squid.
  # The line format is documented at http://wiki.squid-cache.org/Features/Redirectors.
  #
  # @note
  #   The channel ID will be automatically prepended if {Config.concurrency Config.concurrency} is enabled.
  # @param line [String]
  def action(line)
    raise Action.new(line)
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
  # @see #download_like
  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    token = SecureRandom.uuid
    @tokens[token] = block

    EM.add_timer(PURGE_DELAY) {
      @tokens.delete token
    }

    replace_by "http://#{@server_host}:#{@server_port}/#{token}"
  end

  #
  # @!endgroup
  # @!group Helpers
  #


  # Download a resource with the same the headers and body as a rack request.
  #
  # @note
  #   Must be called inside an active fiber if used outside of {#intercept}.
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
  # @see #intercept
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

  # @endgroup

  # @see #define_action
  def method_missing(name, *args)
    custom_action = @custom_actions[name]
    super unless custom_action

    custom_action.call *args
  end

  private
  def squid_handler(line)
    parts = line.split

    chan_id = Config.concurrency ? parts.shift : nil
    url, *extras = parts

    # squid sends https url in the format "domain:port", without the scheme
    # FIXME: https support?
    accept if url && !url.include?('://')

    uri = URI.parse url
    raise InvalidURI if !uri || !uri.host

    @user_callback.call uri, extras

    accept # default action
  rescue Action => action
    chan_id ? "#{chan_id} #{action.line}" : action.line if action.line
  rescue InvalidURI, Addressable::URI::InvalidURIError
    warn "[MiddleSquid] invalid uri received: '#{url}'\n\tin '#{line}'"
  end

  def http_handler(env)
    callback = @tokens[env['PATH_INFO'][1..-1]]

    return [
      404,
      {'Content-Type' => 'text/plain'},
      ['[MiddleSquid] Invalid Token']
    ] unless callback

    request  = Rack::Request.new env
    response = Thin::AsyncResponse.new env

    Fiber.new {
      retval = callback.call request, response

      if retval.is_a?(Array) && retval.size == 3
        status, headers, body = retval

        sanitize_headers! headers

        response.status = status
        response.headers.merge! headers
        response.write body
      end

      response.done
    }.resume

    response.finish
  end

  def sanitize_headers!(dirty)
    clean = {}
    dirty.each {|key, value|
      key = key.split('_').map(&:capitalize).join('-')
      next if IGNORED_HEADERS.include? key

      clean[key] = value
    }

    dirty.clear
    dirty.merge! clean
  end
end
