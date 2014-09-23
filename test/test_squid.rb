require File.expand_path '../helper', __FILE__

class TestSquid < MiniTest::Test
  SQUID_LINE = 'http://cfillion.tk/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  CONCURRENT_LINE = "0 #{SQUID_LINE}".freeze

  make_my_diffs_pretty!

  def setup
    @ms = MiddleSquid.new
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

  def test_squid_handler_invalid_uris
    MiddleSquid::Config.concurrency = false

    bag = []

    stdout, stderr = capture_io do
      @ms.instance_eval do
        @user_callback = proc {}

        bag << squid_handler('')
        bag << squid_handler('hello world')
        bag << squid_handler('http:// extra')
      end
    end

    assert_equal [nil, nil, nil], bag

    assert_empty stdout
    assert_equal [
      "[MiddleSquid] invalid uri received: ''\n",
      "\tin ''\n",

      "[MiddleSquid] invalid uri received: 'hello'\n",
      "\tin 'hello world'\n",

      "[MiddleSquid] invalid uri received: 'http://'\n",
      "\tin 'http:// extra'\n",
    ], stderr.lines
  end
end
