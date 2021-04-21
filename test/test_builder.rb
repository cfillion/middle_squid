require File.expand_path '../helper', __FILE__

class TestBuilder < MiniTest::Test
  class FakeAdapter < MiddleSquid::Adapter
    def say_hello
      @options[:hello]
    end
  end

  def setup
    @obj = MiddleSquid::Builder.new
  end

  def test_from_file
    path = File.expand_path '../resources', __FILE__
    file = path + '/hello.rb'

    stdout, stderr = capture_io do
       @obj = MiddleSquid::Builder.from_file file
    end

    assert_equal "hello #{@obj}\n", stdout
  end

  def test_default_adapter
    assert_equal MiddleSquid::Adapters::Squid, @obj.adapter.class
    assert_same @obj.adapter, @obj.adapter
  end

  def test_custom_adapter
    @obj.use FakeAdapter, hello: 'world'
    assert_equal FakeAdapter, @obj.adapter.class
    assert_equal 'world', @obj.adapter.say_hello
  end

  def test_database
    @obj.database ':memory:'
  end

  def test_blacklist
    assert_empty @obj.blacklists

    bl = @obj.blacklist 'hello', aliases: ['world']
    assert_instance_of MiddleSquid::BlackList, bl
    assert_equal 'hello', bl.category
    assert_equal ['world'], bl.aliases

    assert_equal [bl], @obj.blacklists
  end

  def test_define_action
    assert_empty @obj.custom_actions

    world = proc { :world }
    @obj.define_action :hello, &world

    assert_equal({:hello => world}, @obj.custom_actions)
  end

  def test_define_helper
    assert_equal @obj.method(:define_helper), @obj.method(:define_action)
  end

  def test_define_action_noblock
    error = assert_raises ArgumentError do
      @obj.define_action :hello
    end

    assert_equal 'no block given', error.message
    assert_empty @obj.custom_actions
  end

  def test_handler
    assert_nil @obj.handler

    handler = lambda {}
    @obj.run handler

    assert_equal handler, @obj.handler
  end

  def test_handler_nocall
    error = assert_raises ArgumentError do
      @obj.run 1
    end

    assert_equal 'the handler must respond to #call', error.message
    assert_nil @obj.handler
  end
end
