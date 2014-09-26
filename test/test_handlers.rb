require File.expand_path '../helper', __FILE__

class TestHandlers < MiniTest::Test
  def test_input_line
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

  def test_input_eof
    input = MiddleSquid::Handlers::Input.new nil, proc {|line| nil }

    Timeout::timeout 1 do
      EM.run { input.receive_data "\x00" }
    end
  end

  def test_input_buffer
    bag = []

    input = MiddleSquid::Handlers::Input.new nil, proc {|*args| bag << args }
    capture_io do
      input.receive_data 'h'
      input.receive_data 'e'
      input.receive_data 'l'
      input.receive_data 'l'
      input.receive_data 'o'
      input.receive_data ' '
      input.receive_data 'w'
      input.receive_data 'o'
      input.receive_data 'r'
      input.receive_data 'l'
      input.receive_data 'd'
      input.receive_data "\n"
    end

    assert_equal [['hello world']], bag
  end

  def test_http_constructor
    MiddleSquid::Handlers::HTTP.new '', 0, []
  end
end
