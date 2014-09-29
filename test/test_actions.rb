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
    @obj.instance_eval do
      @server_host = '127.0.0.1'
      @server_port = 8901
    end

    action = assert_raises MiddleSquid::Action do
      EM.run {
        @obj.intercept {}
      }
    end

    assert_match /\AOK rewrite-url=http:\/\/127.0.0.1:8901\/[\w-]+\z/, action.line
  end

  def test_intercept_requires_a_block
    assert_raises ArgumentError do
      @obj.intercept
    end
  end

  def test_define_action
    bag = []

    @obj.define_action(:hello) {|*args| bag << args }
    @obj.hello :world

    assert_equal [[:world]], bag
    refute_includes @obj.class.instance_methods, :hello
  end

  def test_define_action_requires_a_block
    assert_raises ArgumentError do
      @obj.define_action :test
    end
  end

  def test_method_missing
    assert_raises NoMethodError do
      @obj.not_found
    end
  end
end
