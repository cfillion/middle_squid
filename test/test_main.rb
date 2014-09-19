require File.expand_path '../helper', __FILE__

class TestMain < MiniTest::Test
  def setup
    @ms = MiddleSquid.new
  end

  def test_eval
    path = File.expand_path '../resources', __FILE__
    file = path + '/test_eval.rb'

    assert_equal "hello #{@ms}", @ms.eval(file)
  end

  def test_config
    called_with = nil
    @ms.config {|c| called_with = c }

    assert_same MiddleSquid::Config, called_with
  end
end
