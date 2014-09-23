require File.expand_path '../helper', __FILE__

class TestMain < MiniTest::Test
  def setup
    @ms = MiddleSquid.new
  end

  def test_eval
    path = File.expand_path '../resources', __FILE__
    file = path + '/hello.rb'

    stdout, stderr = capture_io do
      @ms.eval file
    end

    assert_equal "hello #{@ms}\n", stdout
  end

  def test_eval_inhibit_run
    path = File.expand_path '../resources', __FILE__
    file = path + '/run.rb'

    Timeout::timeout 1 do
      @ms.eval file, inhibit_run: true
    end
  end

  def test_eval_inhibit_run_reset
    path = File.expand_path '../resources', __FILE__
    file = path + '/fail.rb'

    assert_raises RuntimeError do
      @ms.eval file, inhibit_run: true
    end

    refute @ms.instance_eval { @inhibit_run }, 'reset failed'
  end

  def test_config
    bag = []
    @ms.config {|*args| bag << args }

    assert_equal [[MiddleSquid::Config]], bag
  end

  def test_internal_server_address
    assert_nil @ms.server_host
    assert_nil @ms.server_port
  end

  def test_define_action
    bag = []

    @ms.define_action(:hello) {|*args| bag << args }
    @ms.hello :world

    assert_equal [[:world]], bag
    refute_includes MiddleSquid.instance_methods, :hello
  end

  def test_define_action_requires_a_block
    assert_raises ArgumentError do
      @ms.define_action :test
    end
  end

  def test_method_missing
    assert_raises NoMethodError do
      @ms.not_found
    end
  end

  def test_action
    action = assert_raises MiddleSquid::Action do
      @ms.action 'test'
    end

    assert_equal 'test', action.line
  end

  def test_accept
    action = assert_raises MiddleSquid::Action do
      @ms.accept
    end

    assert_equal 'ERR', action.line
  end

  def test_drop
    action = assert_raises MiddleSquid::Action do
      @ms.drop
    end

    assert_nil action.line
  end

  def test_redirect_301
    action = assert_raises MiddleSquid::Action do
      @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk'
    end

    assert_equal 'OK status=301 url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_redirect_custom_status
    action = assert_raises MiddleSquid::Action do
      @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk', status: 418
    end

    assert_equal 'OK status=418 url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_replace
    action = assert_raises MiddleSquid::Action do
      @ms.replace_by 'http://duckduckgo.com/?q=cfillion tk'
    end

    assert_equal 'OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_intercept
    @ms.instance_eval do
      @server_host = '127.0.0.1'
      @server_port = 8901
    end

    action = assert_raises MiddleSquid::Action do
      EM.run {
        @ms.intercept {}
      }
    end

    assert_match /\AOK rewrite-url=http:\/\/127.0.0.1:8901\/[\w-]+\z/, action.line
  end

  def test_intercept_requires_a_block
    assert_raises ArgumentError do
      @ms.intercept
    end
  end
end
