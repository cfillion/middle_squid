module MiddleSquid::Backends
  # Exposes the signature of Thin's TCP socket.
  #
  # @example Extract current host and port
  #   sockname = EM.get_sockname @thin.backend.signature
  #   @port, @host = Socket.unpack_sockaddr_in sockname
  class Thin < Thin::Backends::TcpServer
    attr_reader :signature

    def initialize(host, port, options)
      super host, port
    end
  end
end
