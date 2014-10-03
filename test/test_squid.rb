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

  def test_concurrent_output
    @con.handler = proc {}
    stdout, stderr = capture_io do
      @con.input CONCURRENT_LINE
    end

    assert_equal "0 ERR\n", stdout
    assert_empty stderr
  end

  def test_accept
    stdout, stderr = capture_io do
      @std.output :accept, {}
    end

    assert_equal "ERR\n", stdout
    assert_empty stderr
  end

  def test_redirect
    stdout, stderr = capture_io do
      @std.output :redirect, {
        :status => 418,
        :url => 'http://test.com/hello world'
      }
    end

    assert_equal "OK status=418 url=http://test.com/hello%20world\n", stdout
    assert_empty stderr
  end

  def test_rewrite
    stdout, stderr = capture_io do
      @std.output :replace, {
        :url => 'http://test.com/hello world'
      }
    end

    assert_equal "OK rewrite-url=http://test.com/hello%20world\n", stdout
    assert_empty stderr
  end

  def test_unsupported
    error = assert_raises MiddleSquid::Error do
      @std.output :test, {}
    end

    assert_equal 'unsupported action: test', error.message
  end
end
