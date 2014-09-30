module MiddleSquid::Backends
  class Thin < Thin::Backends::TcpServer
    attr_reader :signature

    def initialize(host, port, options)
      super host, port
    end
  end
end
