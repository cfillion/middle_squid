require File.expand_path '../helper', __FILE__

class TestSquid < MiniTest::Test
  SQUID_LINE = 'http://cfillion.tk/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  HTTPS_LINE = 'cfillion.tk:443 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'.freeze
  CONCURRENT_LINE = "0 #{SQUID_LINE}".freeze

  make_my_diffs_pretty!

  def setup
    EM.run {
      @std = MiddleSquid::Adapters::Squid.new concurrency: false
      @con = MiddleSquid::Adapters::Squid.new concurrency: true
      EM.next_tick { EM.stop }
    }
  end

  def test_start
    stdout, stderr = capture_io do
      EM.run {
        @std.start
        EM.next_tick { EM.stop }
      }
    end

    # FIXME: I don't know how to test both cases
    if STDOUT.tty?
      assert_match /should be launched from squid/, stderr
    else
      assert_empty stderr
    end
  end

  def test_input
    bag = []

    handler = proc {|*args| bag << args }
    @std.handler = handler
    @con.handler = handler

    capture_io do
      @std.input SQUID_LINE
      @con.input CONCURRENT_LINE
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

    handler = proc { raise MiddleSquid::Action.new 'test' }
    @std.handler = handler
    @con.handler = handler

    stdout, stderr = capture_io do
      @std.input(SQUID_LINE)
    end

    assert_equal "test\n", stdout
    assert_empty stderr

    stdout, stderr = capture_io do
      @con.input(CONCURRENT_LINE)
    end

    assert_equal "0 test\n", stdout
    assert_empty stderr
  end
end
