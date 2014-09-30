require File.expand_path '../helper', __FILE__

class TestSquid < MiniTest::Test
  SQUID_LINE = 'http://cfillion.tk/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  HTTPS_LINE = 'cfillion.tk:443 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  CONCURRENT_LINE = "0 #{SQUID_LINE}".freeze

  make_my_diffs_pretty!

  def setup
    EM.run {
      @obj = MiddleSquid::Adapters::Squid.new
      EM.next_tick { EM.stop }
    }
  end

  def test_input
    bag = []

    @obj.callback = proc {|*args| bag << args }

    capture_io do
      MiddleSquid::Config.concurrency = false
      @obj.input SQUID_LINE

      MiddleSquid::Config.concurrency = true
      @obj.input CONCURRENT_LINE
    end

    uri = MiddleSquid::URI.parse 'http://cfillion.tk/'
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

  def test_output
    bag = []

    @obj.callback = proc { raise MiddleSquid::Action.new 'test' }

    MiddleSquid::Config.concurrency = false
    stdout, stderr = capture_io do
      @obj.input(SQUID_LINE)
    end

    assert_equal "test\n", stdout
    assert_empty stderr

    MiddleSquid::Config.concurrency = true
    stdout, stderr = capture_io do
      @obj.input(CONCURRENT_LINE)
    end

    assert_equal "0 test\n", stdout
    assert_empty stderr
  end
end
