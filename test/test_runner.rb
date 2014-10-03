require File.expand_path '../helper', __FILE__

class TestRunner < MiniTest::Test
  def test_invalid_config
    fake_builder = Class.new
    def fake_builder.handler; nil; end

    error = assert_raises MiddleSquid::Error do
      MiddleSquid::Runner.new fake_builder
    end

    assert_equal 'MiddleSquid is not initialized. Did you call Builder#run in your configuration file?', error.message
  end

  def test_run
    handler = proc { self }

    custom_actions = { :world => proc { 'hello' } }

    fake_adapter = MiniTest::Mock.new
    fake_adapter.expect :handler=, nil, [handler]
    fake_adapter.expect :start, nil, []

    fake_builder = Class.new
    fake_builder.define_singleton_method(:handler) { handler }
    fake_builder.define_singleton_method(:adapter) { fake_adapter }
    fake_builder.define_singleton_method(:custom_actions) { custom_actions }

    EM.run {
      @obj = MiddleSquid::Runner.new fake_builder
      verify_server
      EM.next_tick { EM.stop }
    }

    fake_adapter.verify

    verify_custom_actions
  end

  def verify_server
    assert_instance_of MiddleSquid::Server, @obj.server
    assert_equal '127.0.0.1', @obj.server.host
    assert @obj.server.port > 0, 'port'
  end

  def verify_custom_actions
    assert_equal 'hello', @obj.world

    assert_raises NoMethodError do
      @obj.not_found
    end
  end
end
