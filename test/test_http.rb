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
end
