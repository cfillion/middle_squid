require File.expand_path '../helper', __FILE__

class TestServer < MiniTest::Test
  include Rack::Test::Methods

  def setup
    @server = MiddleSquid::Server.new
    @app = Thin::Async::Test.new @server.method(:handler)
  end

  def app
    @app
  end

  def token_for(&block)
    token = nil

    EM.run {
      token = @server.token_for block
      EM.next_tick { EM.stop }
    }

    token
  end

  def test_start_stop
    EM.run {
      assert_nil @server.host
      assert_nil @server.port

      @server.start

      assert_equal '127.0.0.1', @server.host
      assert_instance_of Fixnum, @server.port
      assert @server.port > 0

      @server.stop

      assert_nil @server.host
      assert_nil @server.port

      EM.next_tick { EM.stop }
    }
  end

  def test_not_found
    get '/not_found'

    assert_equal 404, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_equal '[MiddleSquid] Invalid Token', last_response.body
  end

  def test_token
    bag = []

    tk = token_for {|*args|
      bag << args
      bag << Fiber.current
    }

    get '/' + tk

    assert_equal 200, last_response.status
    assert_empty last_response.body

    (req, res), fiber = bag

    assert_instance_of Rack::Request, req
    assert_instance_of Thin::AsyncResponse, res

    refute_same fiber, Fiber.current
  end

  def test_rack_reply
    tk = token_for {
      [418, {'Hello'=>'World'}, ['hello world']]
    }

    get '/' + tk

    assert_equal 418, last_response.status
    assert_equal 'World', last_response['HELLO']
    assert_equal 'hello world', last_response.body
  end
end
