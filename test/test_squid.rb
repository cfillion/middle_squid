require File.expand_path '../helper', __FILE__

class TestSquid < MiniTest::Test
  SQUID_LINE = '0 http://éacute.com/ 127.0.0.1/localhost.localdomain - GET myip=127.0.0.1 myport=3128'

  def setup
    @ms = MiddleSquid.new
  end

  def run_with(&block)
    EM.run {
      @ms.instance_eval do
        @user_callback = block
        squid_handler SQUID_LINE
      end

      EM.next_tick { EM.stop }
    }
  end

  def test_uri
    uri = nil

    capture_io do
      run_with {|a| uri = a }
    end

    assert_instance_of Addressable::URI, uri
    assert_equal 'xn--acute-9ra.com', uri.host # normalized
  end

  def test_extras
    extras = nil

    capture_io do
      run_with {|a, b| extras = b }
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
    assert_output "0 ERR\n" do
      run_with {}
    end
  end

  def test_accept
    assert_output "0 ERR\n" do
      run_with { @ms.accept; flunk }
    end
  end

  def test_drop
    assert_output '' do
      run_with { @ms.drop; flunk }
    end
  end

  def test_redirect_301
    assert_output "0 OK status=301 url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with { @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk'; flunk }
    end
  end

  def test_redirect_custom_status
    assert_output "0 OK status=418 url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with { @ms.redirect_to 'http://duckduckgo.com/?q=cfillion tk', 418; flunk }
    end
  end

  def test_replace
    assert_output "0 OK rewrite-url=http://duckduckgo.com/?q=cfillion%20tk\n" do
      run_with { @ms.replace_by 'http://duckduckgo.com/?q=cfillion tk'; flunk }
    end
  end

  def test_intercept
    assert_output /^0 OK rewrite-url=http:\/\/127.0.0.1:8918\/[\w-]+\n$/ do
      run_with { @ms.intercept {}; flunk }
    end
  end

  def test_intercept_no_block
    error = assert_raises ArgumentError do
      @ms.intercept
    end

    assert_equal 'no block given', error.message
  end

  def test_invalid_action
    error = assert_raises MiddleSquid::Error do
      run_with { @ms.action :barrel_roll; flunk }
    end

    assert_equal 'invalid action', error.message
  end
end
