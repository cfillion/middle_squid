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

  attr_reader :server_host, :server_port

  def initialize
    @custom_actions = {}
    @tokens = {}
  end

  def eval(file, inhibit_run: false)
    @inhibit_run = inhibit_run

    content = File.read file
    instance_eval content, file
  ensure
    @inhibit_run = false
  end

  def config
    yield Config
  end

  def run(callback)
    return if @inhibit_run

    BlackList.deadline!

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

  def action(line)
    raise Action.new(line)
  end

  def accept
    action 'ERR'
  end

  def drop
    action nil
  end

  def redirect_to(url, status: 301)
    action "OK status=#{status} url=#{URI.escape url}"
  end

  def replace_by(url)
    action "OK rewrite-url=#{URI.escape url}"
  end

  def intercept(&block)
    raise ArgumentError, 'no block given' unless block_given?

    token = SecureRandom.uuid
    @tokens[token] = block

    EM.add_timer(PURGE_DELAY) {
      @tokens.delete token
    }

    tailored_url = "http://#{@server_host}:#{@server_port}/#{token}"

    if @current_uri.scheme == 'http'
      replace_by tailored_url
    else
      redirect_to tailored_url
    end
  end

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

  def define_action(name, &block)
    raise ArgumentError, 'no block given' unless block_given?

    @custom_actions[name] = block
  end

  def method_missing(name, *args)
    custom_action = @custom_actions[name]
    super unless custom_action

    custom_action.call *args
  end

  private
  # @see http://wiki.squid-cache.org/Features/Redirectors
  def squid_handler(line)
    parts = line.split

    chan_id = Config.concurrency ? parts.shift : nil
    url, *extras = parts

    # squid sends https url in the format "domain:port", without the scheme
    url = "https://#{url}" if url && !url.include?('://')

    uri = Addressable::URI.parse url
    raise InvalidURI if !uri || !uri.host

    @current_uri = uri
    @user_callback.call uri, extras

    accept # default action
  rescue Action => action
    chan_id ? "#{chan_id} #{action.line}" : action.line if action.line
  rescue InvalidURI, Addressable::URI::InvalidURIError
    warn "[MiddleSquid] invalid uri received: '#{url}'\n\tin '#{line}'"
  ensure
    @current_uri = nil
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
