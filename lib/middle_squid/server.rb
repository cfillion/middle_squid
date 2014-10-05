module MiddleSquid
  # Manages the internal HTTP server.
  class Server
    DEFAULT_HOST = '127.0.0.1'.freeze
    DEFAULT_PORT = 0

    TOKEN_TIMEOUT = 10

    Thin::Logging.logger = Logger.new STDERR
    Thin::Logging.level = Logger::WARN

    # @return [String]
    attr_reader :host

    # @return [Fixnum]
    attr_reader :port

    def initialize
      @tokens = {}
      @thin = Thin::Server.new DEFAULT_HOST, DEFAULT_PORT, method(:handler),
        :backend => Backends::Thin,
        :signals => false
    end

    def start
      @thin.start

      sockname = EM.get_sockname @thin.backend.signature
      @port, @host = Socket.unpack_sockaddr_in sockname
    end

    def stop
      @thin.stop
      @port = @host = nil
    end

    # Creates a temporary token.
    #
    # @param block [#call] called when the token is requested
    # @return [String] random token
    def token_for(block)
      token = SecureRandom.uuid
      @tokens[token] = block

      EM.add_timer(TOKEN_TIMEOUT) {
        @tokens.delete token
      }

      token
    end

    private
    def handler(env)
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

          headers.sanitize_headers!

          response.status = status
          response.headers.merge! headers
          response.write body
        end

        response.done
      }.resume

      response.finish
    end
  end
end
