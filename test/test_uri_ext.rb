require File.expand_path '../helper', __FILE__

class TestUriExt < MiniTest::Test
  def test_cleanhost
    assert_equal 'cfillion.tk', URI.parse('http://www.cfillion.tk/').cleanhost
    assert_equal 'sub.cfillion.tk', URI.parse('http://sub.cfillion.tk/').cleanhost

    assert_equal 'cfillion.tk', URI.parse('http://cfillion.tk./').cleanhost
    assert_equal 'cfillion.tk', URI.parse('http://cfillion.tk../').cleanhost
  end

  def test_cleanpath
    assert_equal '/a/b', URI.parse('http://host//a//b//').cleanpath
    assert_equal '/a/b', URI.parse('http://host/./a/./b/').cleanpath
    assert_equal '/b', URI.parse('http://host/../a/../b').cleanpath
  end
end
