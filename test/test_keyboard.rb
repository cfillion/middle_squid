require File.expand_path '../helper', __FILE__

class TestKeyboard < MiniTest::Test
  def test_receive_line
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|*args|
      bag << args
    }

    input.receive_line 'hello world'

    assert_equal ['hello world'], bag.shift
    assert_empty bag
  end

  def test_encoding_fix
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|line| bag << line }

    input.receive_line 'hello world'.force_encoding(Encoding::ASCII_8BIT)

    assert_equal Encoding::UTF_8, bag.shift.encoding
    assert_empty bag
  end

  def test_input_eof
    input = MiddleSquid::Backends::Keyboard.new nil, proc {|line| nil }

    Timeout::timeout 1 do
      EM.run { input.receive_data "\x00" }
    end
  end

  def test_line_buffer
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

    assert_equal ['hello world'], bag.shift
    assert_empty bag
  end

  def test_buffer_is_always_cleared
    bag = []

    input = MiddleSquid::Backends::Keyboard.new nil, proc {|*args|
      bag << args
      throw :skip
    }

    catch :skip do
      input.receive_data 'a'
      input.receive_data "\n"
    end

    catch :skip do
      input.receive_data 'b'
      input.receive_data "\n"
    end

    assert_equal ['a'], bag.shift
    assert_equal ['b'], bag.shift
    assert_empty bag
  end
end
