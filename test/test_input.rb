require File.expand_path '../helper', __FILE__

class TestInput < MiniTest::Test
  def test_input
    called_with = nil

    input = MiddleSquid::Input.new nil, proc {|line| called_with = line }
    input.receive_line 'hello world'

    assert_equal called_with, 'hello world'
  end
end
