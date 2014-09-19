class MiddleSquid::Input < EventMachine::Connection
  include EM::Protocols::LineText2

  def initialize(handler)
    @handler = handler
  end

  def receive_line(line)
    @handler.call line
  end
end
