require File.expand_path '../helper', __FILE__

class TestMain < MiniTest::Test
  def setup
    @ms = MiddleSquid.new
  end

  def test_eval
    path = File.expand_path '../resources', __FILE__
    file = path + '/hello.rb'

    stdout, stderr = capture_io do
      @ms.eval file
    end

    assert_equal "hello #{@ms}\n", stdout
  end

  def test_eval_inhibit_run
    path = File.expand_path '../resources', __FILE__
    file = path + '/run.rb'

    Timeout::timeout 1 do
      @ms.eval file, inhibit_run: true
    end
  end

  def test_eval_inhibit_run_reset
    path = File.expand_path '../resources', __FILE__
    file = path + '/fail.rb'

    assert_raises RuntimeError do
      @ms.eval file, inhibit_run: true
    end

    refute @ms.instance_eval { @inhibit_run }, 'reset failed'
  end

  def test_config
    bag = []
    @ms.config {|*args| bag << args }

    assert_equal [[MiddleSquid::Config]], bag
  end

  def test_internal_server_address
    assert_nil @ms.server_host
    assert_nil @ms.server_port
  end
end
