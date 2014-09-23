require File.expand_path '../helper', __FILE__

class TestHandlers < MiniTest::Test
  def test_input
    bag = []

    input = MiddleSquid::Handlers::Input.new nil, proc {|*args|
      bag << args
      'return value'
    }

    stdout, stderr = capture_io do
      input.receive_line 'hello world'
    end

    assert_equal [['hello world']], bag
    assert_equal "return value\n", stdout
    assert_empty stderr
  end

  def test_input_no_reply
    input = MiddleSquid::Handlers::Input.new nil, proc {|line| nil }

    stdout, stderr = capture_io do
      input.receive_line 'hello world'
    end

    assert_empty stdout
    assert_empty stderr
  end

  def test_input_fix_encoding
    bag = []

    input = MiddleSquid::Handlers::Input.new nil, proc {|line| bag << line }

    capture_io do
      input.receive_line 'hello world'.force_encoding(Encoding::ASCII_8BIT)
    end

    assert_equal Encoding::UTF_8, bag[0].encoding
  end
end
