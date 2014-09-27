require File.expand_path '../helper', __FILE__

class TestUriExt < MiniTest::Test
  def test_cleanhost
    assert_equal '.cfillion.tk',
      Addressable::URI.parse('http://cfillion.tk/').cleanhost

    assert_equal '.cfillion.tk',
      Addressable::URI.parse('http://www.cfillion.tk/').cleanhost

    assert_equal '.sub.cfillion.tk',
      Addressable::URI.parse('http://sub.cfillion.tk/').cleanhost
  end

  def test_cleanhost_trailing_dots
    assert_equal '.cfillion.tk',
      Addressable::URI.parse('http://cfillion.tk./').cleanhost

    assert_equal '.cfillion.tk',
      Addressable::URI.parse('http://cfillion.tk../').cleanhost
  end

  def test_cleanhost_normalized
    cleanhost = Addressable::URI.parse('http://éacute.com').cleanhost

    assert_equal '.xn--acute-9ra.com', cleanhost
    assert_equal Encoding::UTF_8, cleanhost.encoding
  end

  def test_cleanpath
    assert_equal 'a/page.html',
      Addressable::URI.parse('http://host/a/page.html').cleanpath

    assert_empty Addressable::URI.parse('http://host').cleanpath
    assert_empty Addressable::URI.parse('http://host/').cleanpath
  end

  def test_cleanpath_cheaptricks
    assert_equal 'a/b',
      Addressable::URI.parse('http://host//a//b//').cleanpath

    assert_equal 'a/b',
      Addressable::URI.parse('http://host/./a/./b/').cleanpath

    assert_equal 'b',
      Addressable::URI.parse('http://host/../a/../b').cleanpath
  end

  def test_cleanpath_indexes
    assert_equal 'a',
      Addressable::URI.parse('http://host/a/index.html').cleanpath

    assert_equal 'a',
      Addressable::URI.parse('http://host/a/index.php').cleanpath

    assert_equal 'a',
      Addressable::URI.parse('http://host/a/Default.aspx').cleanpath

    assert_equal 'a',
      Addressable::URI.parse('http://host/a/default.aspx').cleanpath
  end

  def test_cleanpath_normalized
    cleanpath = Addressable::URI.parse('http://cfillion.tk/test test').cleanpath

    assert_equal 'test%20test', cleanpath
    assert_equal Encoding::UTF_8, cleanpath.encoding
  end
end
