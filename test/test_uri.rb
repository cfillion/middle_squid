require File.expand_path '../helper', __FILE__

class TestUriExt < MiniTest::Test
  def test_cleanhost
    assert_equal '.cfillion.tk',
      MiddleSquid::URI.parse('http://cfillion.tk/').cleanhost

    assert_equal '.cfillion.tk',
      MiddleSquid::URI.parse('http://www.cfillion.tk/').cleanhost

    assert_equal '.sub.cfillion.tk',
      MiddleSquid::URI.parse('http://sub.cfillion.tk/').cleanhost
  end

  def test_cleanhost_trailing_dots
    assert_equal '.cfillion.tk',
      MiddleSquid::URI.parse('http://cfillion.tk./').cleanhost

    assert_equal '.cfillion.tk',
      MiddleSquid::URI.parse('http://cfillion.tk../').cleanhost
  end

  def test_cleanhost_normalized
    cleanhost = MiddleSquid::URI.parse('http://éacute.com').cleanhost

    assert_equal '.xn--acute-9ra.com', cleanhost
    assert_equal Encoding::UTF_8, cleanhost.encoding
  end

  def test_cleanpath
    assert_equal 'a/page.html/',
      MiddleSquid::URI.parse('http://host/a/page.html').cleanpath

    assert_empty MiddleSquid::URI.parse('http://host').cleanpath
    assert_empty MiddleSquid::URI.parse('http://host/').cleanpath
  end

  def test_cleanpath_cheaptricks
    assert_equal 'a/b/',
      MiddleSquid::URI.parse('http://host//a//b//').cleanpath

    assert_equal 'a/b/',
      MiddleSquid::URI.parse('http://host/./a/./b/').cleanpath

    assert_equal 'b/',
      MiddleSquid::URI.parse('http://host/../a/../b').cleanpath
  end

  def test_cleanpath_indexes
    assert_equal 'a/',
      MiddleSquid::URI.parse('http://host/a/index.html').cleanpath

    assert_equal 'a/',
      MiddleSquid::URI.parse('http://host/a/index.php').cleanpath

    assert_equal 'a/',
      MiddleSquid::URI.parse('http://host/a/Default.aspx').cleanpath

    assert_equal 'a/',
      MiddleSquid::URI.parse('http://host/a/default.aspx').cleanpath
  end

  def test_cleanpath_normalized
    cleanpath = MiddleSquid::URI.parse('http://cfillion.tk/test test').cleanpath

    assert_equal 'test%20test/', cleanpath
    assert_equal Encoding::UTF_8, cleanpath.encoding
  end
end
