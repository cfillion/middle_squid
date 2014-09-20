class MiddleSquid::Input < EventMachine::Connection
  include EM::Protocols::LineText2

  def initialize(handler)
    @handler = handler
  end

  def receive_line(line)
    # EventMachine sends ASCII-8BIT strings, somehow preventing the databases queries to match
    @handler.call line.force_encoding(Encoding::UTF_8)
  end
end
