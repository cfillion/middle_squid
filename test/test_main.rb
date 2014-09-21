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
    called_with = nil
    @ms.config {|c| called_with = c }

    assert_same MiddleSquid::Config, called_with
  end
end
