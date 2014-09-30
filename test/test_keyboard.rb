require File.expand_path '../helper', __FILE__

class TestKeyboard < MiniTest::Test
  def test_input_line
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|*args|
      bag << args
    }

    input.receive_line 'hello world'

    assert_equal [['hello world']], bag
  end

  def test_input_fix_encoding
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|line| bag << line }

    input.receive_line 'hello world'.force_encoding(Encoding::ASCII_8BIT)

    assert_equal Encoding::UTF_8, bag[0].encoding
  end

  def test_input_eof
    input = MiddleSquid::Backends::Keyboard.new nil, proc {|line| nil }

    Timeout::timeout 1 do
      EM.run { input.receive_data "\x00" }
    end
  end

  def test_input_buffer
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|*args| bag << args }
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

    assert_equal [['hello world']], bag
  end
end
