require File.expand_path '../helper', __FILE__

class TestHandlers < MiniTest::Test
  def test_input
    called_with = nil

    input = MiddleSquid::Handlers::Input.new nil, proc {|line|
      called_with = line
      'return value'
    }

    stdout, stderr = capture_io do
      input.receive_line 'hello world'
    end

    assert_equal called_with, 'hello world'
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

  def test_fix_encoding
    called_with = nil

    input = MiddleSquid::Handlers::Input.new nil, proc {|line| called_with = line }

    capture_io do
      input.receive_line ''.force_encoding(Encoding::ASCII_8BIT)
    end

    assert_equal Encoding::UTF_8, called_with.encoding
  end
end
