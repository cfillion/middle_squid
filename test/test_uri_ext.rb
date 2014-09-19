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

    assert_equal '/a', URI.parse('http://host/a/index.html').cleanpath
    assert_equal '/a', URI.parse('http://host/a/index.php').cleanpath
    assert_equal '/a', URI.parse('http://host/a/Default.aspx').cleanpath
    assert_equal '/a', URI.parse('http://host/a/default.aspx').cleanpath

    assert_equal '/a/page.html', URI.parse('http://host/a/page.html').cleanpath
  end
end
