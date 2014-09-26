require File.expand_path '../helper', __FILE__

class TestHTTP < MiniTest::Test
  include Rack::Test::Methods

  def setup
    @ms = MiddleSquid.new
    @app = Thin::Async::Test.new @ms.method(:http_handler)
  end

  def app
    @app
  end

  def register_token_for(&block)
    @ms.instance_eval do
      @tokens['test'] = block
    end
  end

  def test_not_found
    get '/not_found'

    assert_equal 404, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_equal '[MiddleSquid] Invalid Token', last_response.body
  end

  def test_token
    bag = []

    register_token_for {|*args|
      bag << args
      bag << Fiber.current
    }

    get '/test'

    assert_equal 200, last_response.status
    assert_empty last_response.body

    (req, res), fiber = bag

    assert_instance_of Rack::Request, req
    assert_instance_of Thin::AsyncResponse, res

    refute_same fiber, Fiber.current
  end

  def test_rack_reply
    register_token_for {
      [418, {'Hello'=>'World'}, ['hello world']]
    }

    get '/test'

    assert_equal 418, last_response.status
    assert_equal 'World', last_response['HELLO']
    assert_equal 'hello world', last_response.body
  end

  def download_wrapper(uri, env)
    bag = []
    req = Rack::Request.new env

    EM.run {
      Fiber.new {
        bag << @ms.download_like(req, uri)
      }.resume
      EM.next_tick { EM.stop }
    }

    assert_equal 1, bag.size
    bag[0]
  end

  def test_download
    uri = Addressable::URI.parse 'http://test.com/path?query=string'

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
    uri = Addressable::URI.parse 'http://test.com/'

    stub = stub_request(:post, uri).
      to_return(:status => 200, :body => '')

    download_wrapper uri,
      'REQUEST_METHOD' => 'POST',
      'rack.input' => StringIO.new

    assert_requested stub
  end

  def test_download_error
    uri = Addressable::URI.parse 'http://test.com/'

    stub = stub_request(:get, uri).to_timeout

    status, headers, body = download_wrapper uri,
      'REQUEST_METHOD' => 'GET',
      'rack.input' => StringIO.new

    assert_requested stub
    assert_equal 'WebMock timeout error', status
    assert_nil headers
    assert_nil body
  end
end
