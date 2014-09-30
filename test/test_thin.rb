require File.expand_path '../helper', __FILE__

class TestThin < MiniTest::Test
  def test_constructor
    MiddleSquid::Backends::Thin.new '', 0, []
  end
end
