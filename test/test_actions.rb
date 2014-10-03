require File.expand_path '../helper', __FILE__

class TestActions < MiniTest::Test
  FakeClass = Class.new { include MiddleSquid::Actions }

  def setup
    @obj = FakeClass.new
  end

  def test_action
    action = assert_raises MiddleSquid::Action do
      @obj.action 'test'
    end

    assert_equal 'test', action.line
  end

  def test_accept
    action = assert_raises MiddleSquid::Action do
      @obj.accept
    end

    assert_equal 'ERR', action.line
  end

  def test_drop
    action = assert_raises MiddleSquid::Action do
      @obj.drop
    end

    assert_nil action.line
  end

  def test_redirect_301
    action = assert_raises MiddleSquid::Action do
      @obj.redirect_to 'http://duckduckgo.com/?q=cfillion tk'
    end

    assert_equal 'OK status=301 url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_redirect_custom_status
    action = assert_raises MiddleSquid::Action do
      @obj.redirect_to 'http://duckduckgo.com/?q=cfillion tk', status: 418
    end

    assert_equal 'OK status=418 url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_replace
    action = assert_raises MiddleSquid::Action do
      @obj.replace_by 'http://duckduckgo.com/?q=cfillion tk'
    end

    assert_equal 'OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_intercept
    mock = MiniTest::Mock.new
    mock.expect :token_for, 'qwfpgjluy', [Proc]
    mock.expect :host, '127.0.0.1'
    mock.expect :port, 8901
    @obj.define_singleton_method(:server) { mock }

    action = assert_raises MiddleSquid::Action do
      EM.run {
        @obj.intercept {}
        EM.next_tick { EM.stop }
      }
    end

    assert_equal 'OK rewrite-url=http://127.0.0.1:8901/qwfpgjluy', action.line
    mock.verify
  end

  def test_intercept_requires_a_block
    assert_raises ArgumentError do
      @obj.intercept
    end
  end
end
