require File.expand_path '../helper', __FILE__

class TestAdapter < MiniTest::Test
  def setup
    @obj = MiddleSquid::Adapter.new
  end
  
  def test_handler
    bag = []

    @obj.handler = proc {|*args| bag << args }

    @obj.define_singleton_method(:output) { |*args| bag << args }

    @obj.handle 'http://test.com', ['hello', 'world']

    uri, extras = bag.shift
    assert_instance_of MiddleSquid::URI, uri
    assert_equal 'http://test.com', uri.to_s
    assert_equal ['hello', 'world'], extras

    assert_equal [:accept, {}], bag.shift # default action

    assert_empty bag
  end

  def test_output
    bag = []

    @obj.handler = proc { throw :action, [:type, :options] }

    @obj.define_singleton_method(:output) { |*args| bag << args }

    @obj.handle 'http://test.com', []

    assert_equal [:type, :options], bag.shift
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
