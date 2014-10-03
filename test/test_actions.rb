require File.expand_path '../helper', __FILE__

class TestActions < MiniTest::Test
  FakeClass = Class.new { include MiddleSquid::Actions }

  def setup
    @obj = FakeClass.new
  end

  def test_accept
    action = catch :action do
      @obj.accept
    end

    assert_equal [:accept, {}], action
  end

  def test_redirect_301
    action = catch :action do
      @obj.redirect_to 'url'
    end

    assert_equal [:redirect, {
      :status => 301,
      :url => 'url'
    }], action
  end

  def test_redirect_custom_status
    action = catch :action do
      @obj.redirect_to 'new url', status: 418
    end

    assert_equal [:redirect, {
      :status => 418,
      :url => 'new url'
    }], action
  end

  def test_replace
    action = catch :action do
      @obj.replace_by 'http://duckduckgo.com/'
    end

    assert_equal [:replace, {
      :url => 'http://duckduckgo.com/'
    }], action
  end

  def test_intercept
    mock = MiniTest::Mock.new
    mock.expect :token_for, 'qwfpgjluy', [Proc]
    mock.expect :host, '127.0.0.1'
    mock.expect :port, 8901
    @obj.define_singleton_method(:server) { mock }

    action = catch :action do
      EM.run {
        @obj.intercept {}
        EM.next_tick { EM.stop }
      }
    end

    assert_equal [:replace, {
      :url => 'http://127.0.0.1:8901/qwfpgjluy'
    }], action

    mock.verify
  end

  def test_intercept_requires_a_block
    assert_raises ArgumentError do
      @obj.intercept
    end
  end
end
