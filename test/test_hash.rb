require File.expand_path '../helper', __FILE__

class TestHash < MiniTest::Test
  def test_sanitize_headers
    before = {
      'Chunky-Bacon' => nil,
      'CONNECTION' => nil,
      'CONTENT_ENCODING' => nil,
      'CONTENT_LENGTH' => nil,
      'HELLO_WORLD' => nil,
      'HOST' => nil,
      'TEST' => nil,
      'Transfer-Encoding' => nil,
      'TRANSFER_ENCODING' => nil,
      'VERSION' => nil,
    }

    after = {
      'Chunky-Bacon' => nil,
      'Hello-World' => nil,
      'Test' => nil,
    }

    before.sanitize_headers!

    assert_equal after, before
  end
end
