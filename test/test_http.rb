require File.expand_path '../helper', __FILE__

class TestHTTP < MiniTest::Test
  def test_server
    assert_instance_of MiddleSquid::HTTP::Server, MiddleSquid::HTTP.server
    assert_same MiddleSquid::HTTP.server, MiddleSquid::HTTP.server
  end
end
