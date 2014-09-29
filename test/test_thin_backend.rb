require File.expand_path '../helper', __FILE__

class TestThinBackend < MiniTest::Test
  def test_constructor
    MiddleSquid::HTTP::ThinBackend.new '', 0, []
  end
end
