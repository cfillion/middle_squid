require File.expand_path '../helper', __FILE__

class TestMain < MiniTest::Test
  SQUID_LINE = 'http://cfillion.tk/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  CONCURRENT_LINE = "0 #{SQUID_LINE}".freeze

  make_my_diffs_pretty!

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
    called_with = nil
    @ms.config {|c| called_with = c }

    assert_same MiddleSquid::Config, called_with
  end

  def test_define_action
    called = false
    @ms.define_action(:abc) { called = true }
    @ms.abc

    assert called
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

  def test_replace_by_url
    action = assert_raises MiddleSquid::Action do
      @ms.replace_by 'http://duckduckgo.com/?q=cfillion tk'
    end

    assert_equal 'OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk', action.line
  end

  def test_squid_handler_arguments
    bag = []

    @ms.instance_eval do
      @user_callback = proc {|*args| bag << args }

      MiddleSquid::Config.concurrency = false
      squid_handler SQUID_LINE

      MiddleSquid::Config.concurrency = true
      squid_handler CONCURRENT_LINE
    end

    uri = Addressable::URI.parse 'http://cfillion.tk/'
    extras = [
      '127.0.0.1/localhost.localdomain',
      '-',
      'GET',
      'myip=127.0.0.1',
      'myport=3128'
    ]

    assert_equal [
      [uri, extras],
      [uri, extras],
    ], bag
  end

  def test_squid_handler_output
    bag = []

    @ms.instance_eval do
      @user_callback = proc { action 'test' }

      MiddleSquid::Config.concurrency = false
      bag << squid_handler(SQUID_LINE)

      MiddleSquid::Config.concurrency = true
      bag << squid_handler(CONCURRENT_LINE)
    end

    assert_equal ['test', '0 test'], bag
  end

  def test_squid_handler_drop
    bag = []

    @ms.instance_eval do
      @user_callback = proc { action nil }

      MiddleSquid::Config.concurrency = false
      bag << squid_handler(SQUID_LINE)

      MiddleSquid::Config.concurrency = true
      bag << squid_handler(CONCURRENT_LINE)
    end

    assert_equal [nil, nil], bag
  end

  def test_squid_handler_default_action
    bag = []

    @ms.instance_eval do
      @user_callback = proc {}

      MiddleSquid::Config.concurrency = false
      bag << squid_handler(SQUID_LINE)

      MiddleSquid::Config.concurrency = true
      bag << squid_handler(CONCURRENT_LINE)
    end

    assert_equal ['ERR', '0 ERR'], bag
  end
end
