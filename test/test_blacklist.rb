require File.expand_path '../helper', __FILE__

class TestBlackList < MiniTest::Test
  include MiddleSquid::Database

  DOMAINS = %w{
    .cfillion.tk
    .duckduckgo.com
    .sub.stackoverflow.com
    .analytics.google.com
    .anidb.net
  }

  URLS = [
    %w[.google.com analytics/],
    %w[.youtube.com watch/],
    %w[.github.com user/],
    %w[.host.net file.html/],
    %w[.host.net index.html/],
  ]

  def setup
    db.transaction

    db.execute 'DELETE FROM domains' 
    db.execute 'DELETE FROM urls' 

    DOMAINS.each_with_index {|domain, index|
      db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
        [index % 2 == 0 ? 'even' : 'odd', domain]
    }

    URLS.each_with_index {|url, index|
      db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
        [index % 2 == 0 ? 'even' : 'odd', *url]
    }

    db.commit
  end

  def teardown
    MiddleSquid::BlackList.class_eval '@@instances.clear'
  end

  def test_category
    bl = MiddleSquid::BlackList.new 'cat_name'
    assert_equal 'cat_name', bl.category
  end

  def test_aliases_default
    bl = MiddleSquid::BlackList.new 'cat_name'
    assert_equal [], bl.aliases
  end

  def test_aliases_custom
    bl = MiddleSquid::BlackList.new 'cat_name', aliases: ['name_cat']
    assert_equal ['name_cat'], bl.aliases
  end

  def test_instances
    MiddleSquid::BlackList.class_eval '@@instances = []'

    assert_empty MiddleSquid::BlackList.instances

    first = MiddleSquid::BlackList.new 'neko'
    second = MiddleSquid::BlackList.new 'inu'

    assert_equal [first, second], MiddleSquid::BlackList.instances
  end

  def test_unmatch
    uri = MiddleSquid::URI.parse('http://anidb.net/a9002')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain? uri
    refute odd.include_url? uri
    refute odd.include? uri
  end

  def test_domain
    uri = MiddleSquid::URI.parse('http://cfillion.tk/love-of-babble/')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain? uri
    refute even.include_url? uri
    assert even.include? uri
  end

  def test_domain_trailing_dots
    uri = MiddleSquid::URI.parse('http://cfillion.tk...')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain? uri
    assert even.include? uri
  end

  def test_domain_partial_match
    uri1 = MiddleSquid::URI.parse('http://www.anidb.net/')
    uri2 = MiddleSquid::URI.parse('http://abcde.anidb.net/')
    uri3 = MiddleSquid::URI.parse('http://bus.sub.stackoverflow.com/')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain?(uri1), 'www'
    assert even.include? uri1

    assert even.include_domain?(uri2), 'any subdomain'
    assert even.include? uri2

    assert even.include_domain?(uri3), 'sub-sub-domain'
    assert even.include? uri3
  end

  def test_domain_right_match
    uri = MiddleSquid::URI.parse('http://google.com')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain? uri
    refute odd.include? uri
  end

  def test_domain_left_match
    uri = MiddleSquid::URI.parse('http://duckduckgo/')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain? uri
    refute odd.include? uri
  end

  def test_domain_wrong_subdomain
    uri = MiddleSquid::URI.parse('http://fakeanalytics.google.com/')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain? uri
    refute odd.include? uri
  end

  def test_url
    uri = MiddleSquid::URI.parse('http://google.com/analytics')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    refute even.include_domain? uri
    assert even.include? uri
  end

  def test_url_wrong_extension
    uri = MiddleSquid::URI.parse('http://host.net/file.php')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_url? uri
    refute odd.include? uri
  end

  def test_url_partial_path
    uri = MiddleSquid::URI.parse('http://github.com/us')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_url? uri
    refute odd.include? uri
  end

  def test_url_left_match
    uri = MiddleSquid::URI.parse('http://host.net/file.html_ohno')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_url? uri
    refute odd.include? uri
  end

  def test_url_longer_path
    uri = MiddleSquid::URI.parse('http://github.com/user/repository')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_url_query_string
    uri = MiddleSquid::URI.parse('http://github.com/user?tab=repositories')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_url_cheap_tricks
    uri = MiddleSquid::URI.parse('http://google.com//maps/../analytics/./')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_group_demo
    uri = MiddleSquid::URI.parse('http://youtube.com/watch?v=test')

    even = MiddleSquid::BlackList.new 'even'
    odd = MiddleSquid::BlackList.new 'odd'

    group = [even, odd]

    assert group.any? {|bl| bl.include? uri }
  end

  def test_deadline
    MiddleSquid::BlackList.deadline!

    error = assert_raises MiddleSquid::Error do
      MiddleSquid::BlackList.new 'test'
    end

    assert_equal 'blacklists cannot be initialized inside the squid helper', error.message
  ensure
    # reset the deadline for the other tests
    MiddleSquid::BlackList.class_eval '@@too_late = false'
  end
end
