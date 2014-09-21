require File.expand_path '../helper', __FILE__

class TestSquid < MiniTest::Test
  SQUID_LINE = 'http://cfillion.tk/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'
  CONCURRENT_LINE = "0 #{SQUID_LINE}"

  def setup
    @ms = MiddleSquid.new
  end

  def run_with(line, &block)
    EM.run {
      @ms.instance_eval do
        @user_callback = block
        squid_handler line
      end

      EM.next_tick { EM.stop }
    }
  end

  def test_uri
    MiddleSquid::Config.concurrency = false

    uri = nil

    capture_io do
      run_with(SQUID_LINE) {|a| uri = a }
    end

    assert_instance_of Addressable::URI, uri
    assert_equal 'cfillion.tk', uri.host
  end

  def test_uri_concurrent
    MiddleSquid::Config.concurrency = true

    uri = nil

    capture_io do
      run_with(CONCURRENT_LINE) {|a| uri = a }
    end

    assert_instance_of Addressable::URI, uri
    assert_equal 'cfillion.tk', uri.host
  end

  def test_extras
    MiddleSquid::Config.concurrency = false

    extras = nil

    capture_io do
      run_with(SQUID_LINE) {|a, b| extras = b }
    end

    assert_equal [
      '127.0.0.1/localhost.localdomain',
      '-',
      'GET',
      'myip=127.0.0.1',
      'myport=3128'
    ], extras
  end

  def test_extras_concurrent
    MiddleSquid::Config.concurrency = true

    extras = nil

    capture_io do
      run_with(CONCURRENT_LINE) {|a, b| extras = b }
    end

    assert_equal [
      '127.0.0.1/localhost.localdomain',
      '-',
      'GET',
      'myip=127.0.0.1',
      'myport=3128'
    ], extras
  end

  def test_accept_by_default
    MiddleSquid::Config.concurrency = false

    assert_output "ERR\n" do
      run_with(SQUID_LINE) {}
    end
  end

  def test_accept
    MiddleSquid::Config.concurrency = false

    assert_output "ERR\n" do
      run_with(SQUID_LINE) { @ms.accept; flunk }
    end
  end

  def test_accept_concurrent
    MiddleSquid::Config.concurrency = true

    assert_output "0 ERR\n" do
      run_with(CONCURRENT_LINE) { @ms.accept; flunk }
    end
  end

  def test_drop
    MiddleSquid::Config.concurrency = false

    assert_output '' do
      run_with(SQUID_LINE) { @ms.drop; flunk }
    end
  end

  def test_redirect_301
    MiddleSquid::Config.concurrency = false

    assert_output "OK status=301 url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with(SQUID_LINE) {
        @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk'
        flunk
      }
    end
  end

  def test_redirect_concurrent
    MiddleSquid::Config.concurrency = true

    assert_output "0 OK status=301 url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with(CONCURRENT_LINE) {
        @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk'
        flunk
      }
    end
  end

  def test_redirect_custom_status
    MiddleSquid::Config.concurrency = false

    assert_output "OK status=418 url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with(SQUID_LINE) {
        @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk', 418
        flunk
      }
    end
  end

  def test_replace
    MiddleSquid::Config.concurrency = false

    assert_output "OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with(SQUID_LINE) {
        @ms.replace_by 'http://duckduckgo.com/?q=cfillion tk'
        flunk
      }
    end
  end

  def test_replace_concurrent
    MiddleSquid::Config.concurrency = true

    assert_output "0 OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with(CONCURRENT_LINE) {
        @ms.replace_by 'http://duckduckgo.com/?q=cfillion tk'
        flunk
      }
    end
  end

  def test_intercept
    MiddleSquid::Config.concurrency = false

    assert_output /\AOK rewrite-url=http:\/\/127.0.0.1:8918\/[\w-]+\Z/ do
      run_with(SQUID_LINE) { @ms.intercept {}; flunk }
    end
  end

  def test_intercept_concurrent
    MiddleSquid::Config.concurrency = true

    assert_output /\A0 OK rewrite-url=http:\/\/127.0.0.1:8918\/[\w-]+\Z/ do
      run_with(CONCURRENT_LINE) { @ms.intercept {}; flunk }
    end
  end

  def test_intercept_no_block
    error = assert_raises ArgumentError do
      @ms.intercept
    end

    assert_equal 'no block given', error.message
  end

  def test_invalid_action
    MiddleSquid::Config.concurrency = false

    error = assert_raises MiddleSquid::Error do
      run_with(SQUID_LINE) { @ms.action :barrel_roll; flunk }
    end

    assert_equal 'invalid action', error.message
  end
end
