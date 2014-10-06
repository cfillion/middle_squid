require File.expand_path '../helper', __FILE__

class TestHelpers < MiniTest::Test
  FakeClass = Class.new { include MiddleSquid::Helpers }

  def setup
    @obj = FakeClass.new
  end

  def download_wrapper(uri, env)
    bag = []
    req = Rack::Request.new env

    EM.run {
      Fiber.new {
        bag << @obj.download_like(req, uri)
      }.resume
      EM.next_tick { EM.stop }
    }

    assert_equal 1, bag.size
    bag[0]
  end

  def test_download
    uri = MiddleSquid::URI.parse 'http://test.com/path?query=string'

    stub = stub_request(:get, uri).
      with(:body => 'request%20body', :headers => {'User-Agent'=>'Mozilla/5.0', 'Chunky' => 'bacon', 'Content-Type'=>'test/plain'}).
      to_return(:status => 200, :body => 'response', :headers => {'CHUNKY_BACON' => 'Hello World'})

    status, headers, body = download_wrapper uri,
      'REQUEST_METHOD' => 'GET',
      'CONTENT_TYPE' => 'test/plain',
      'HTTP_CHUNKY' => 'bacon',
      'HTTP_CONNECTION' => 'ignored',
      'HTTP_USER_AGENT' => 'Mozilla/5.0',
      'rack.input' => StringIO.new('request%20body')

    assert_requested stub
    assert_not_requested :get, uri, :headers => {'Connection' => 'ignored'}

    assert_equal 200, status
    assert_equal({'Chunky-Bacon' => 'Hello World'}, headers)
    assert_equal 'response', body
  end

  def test_download_method
    uri = MiddleSquid::URI.parse 'http://test.com/'

    stub = stub_request(:post, uri).
      to_return(:status => 200, :body => '')

    download_wrapper uri,
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new

    assert_requested stub
  end

  def test_download_error
    uri = MiddleSquid::URI.parse 'http://test.com/'

    stub = stub_request(:get, uri).to_timeout

    status, headers, body = download_wrapper uri,
      'REQUEST_METHOD' => 'GET',
      'rack.input' => StringIO.new

    assert_requested stub

    assert_equal 520, status
    assert_equal({'Content-Type' => 'text/plain'}, headers)
    assert_equal '[MiddleSquid] WebMock timeout error', body
  end
end
