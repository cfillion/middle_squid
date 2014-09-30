require File.expand_path '../helper', __FILE__

class TestAdapter < MiniTest::Test
  def setup
    @obj = MiddleSquid::Adapter.new
  end
  
  def test_callback
    bag = []

    @obj.callback = proc {|*args| bag << args }

    @obj.define_singleton_method(:output) { |*args| bag << args }

    @obj.handle 'http://test.com', ['hello', 'world']

    uri, extras = bag.shift
    assert_instance_of MiddleSquid::URI, uri
    assert_equal 'http://test.com', uri.to_s
    assert_equal ['hello', 'world'], extras

    default_action = bag.shift[0]
    assert_equal 'ERR', default_action.line

    assert_empty bag
  end

  def test_output
    action = MiddleSquid::Action.new 'test'
    bag = []

    @obj.callback = proc { raise action }

    @obj.define_singleton_method(:output) { |*args| bag << args }

    @obj.handle 'http://test.com', []

    assert_equal [action], bag.shift
    assert_empty bag
  end

  def test_invalid_urls
    stdout, stderr = capture_io do
      @obj.handle '', []
      @obj.handle 'http://', []
      @obj.handle 'hello world', []
    end

    assert_empty stdout
    assert_equal [
      "[MiddleSquid] invalid URL received: ''\n",
      "[MiddleSquid] invalid URL received: 'http://'\n",
      "[MiddleSquid] invalid URL received: 'hello world'\n",
    ], stderr.lines
  end
end
