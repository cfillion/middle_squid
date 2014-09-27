require File.expand_path '../helper', __FILE__

class TestBlackList < MiniTest::Test
  include MiddleSquid::Database

  DOMAINS = %w{
    .cfillion.tk .duckduckgo.com .sub.stackoverflow.com .analytics.google.com .anidb.net
  }

  URLS = [
    %w[.google.com analytics], %w[.youtube.com watch], %w[.github.com user]
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

  def test_instances
    MiddleSquid::BlackList.class_eval '@@instances = []'

    assert_empty MiddleSquid::BlackList.instances

    first = MiddleSquid::BlackList.new 'neko'
    second = MiddleSquid::BlackList.new 'inu'

    assert_equal [first, second], MiddleSquid::BlackList.instances
  end

  def test_unmatch
    uri = Addressable::URI.parse('http://anidb.net/a9002')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain? uri
    refute odd.include_url? uri
    refute odd.include? uri
  end

  def test_domain
    uri = Addressable::URI.parse('http://cfillion.tk/love-of-babble/')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain? uri
    refute even.include_url? uri
    assert even.include? uri
  end

  def test_domain_trailing_dots
    uri = Addressable::URI.parse('http://cfillion.tk...')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain? uri
    assert even.include? uri
  end

  def test_domain_partial_match
    uri1 = Addressable::URI.parse('http://www.anidb.net/')
    uri2 = Addressable::URI.parse('http://abcde.anidb.net/')
    uri3 = Addressable::URI.parse('http://bus.sub.stackoverflow.com/')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_domain?(uri1), 'www'
    assert even.include? uri1

    assert even.include_domain?(uri2), 'any subdomain'
    assert even.include? uri2

    assert even.include_domain?(uri3), 'sub-sub-domain'
    assert even.include? uri3
  end

  def test_domain_partial_unmatch
    uri1 = Addressable::URI.parse('http://google.com')
    uri2 = Addressable::URI.parse('http://duckduckgo/')
    uri3 = Addressable::URI.parse('http://fakeanalytics.google.com/')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_domain?(uri1), 'right match'
    refute odd.include? uri1

    refute odd.include_domain?(uri2), 'left match'
    refute odd.include? uri2

    refute odd.include_domain?(uri3), 'partial subdomain match'
    refute odd.include? uri3
  end

  def test_url
    uri = Addressable::URI.parse('http://google.com/analytics')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    refute even.include_domain? uri
    assert even.include? uri
  end


  def test_url_tailing_dots
    uri = Addressable::URI.parse('http://www.google.com.../analytics')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_url_partial_domain_match
    uri1 = Addressable::URI.parse('http://www.google.com/analytics/')
    uri2 = Addressable::URI.parse('http://test.google.com/analytics/')
    uri3 = Addressable::URI.parse('http://bus.test.google.com/analytics')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url?(uri1), 'www'
    assert even.include? uri1

    assert even.include_url?(uri2), 'any subdomain'
    assert even.include? uri2

    assert even.include_url?(uri3), 'sub-sub-domain'
  end

  def test_url_partial_domain_unmatch
    uri1 = Addressable::URI.parse('http://tube.com/watch')
    uri2 = Addressable::URI.parse('http://youtube/watch')
    odd = MiddleSquid::BlackList.new 'odd'

    refute odd.include_url?(uri1), 'right match'
    refute odd.include? uri1

    refute odd.include_url?(uri2), 'left match'
    refute odd.include? uri2
  end

  def test_url_longer_path
    uri = Addressable::URI.parse('http://github.com/user/repository')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_url_partial_path
    uri = Addressable::URI.parse('http://github.com/us')
    even = MiddleSquid::BlackList.new 'even'

    refute even.include_url? uri
    refute even.include? uri
  end

  def test_url_cheap_tricks
    uri = Addressable::URI.parse('http://google.com//maps/../analytics/./')
    even = MiddleSquid::BlackList.new 'even'

    assert even.include_url? uri
    assert even.include? uri
  end

  def test_group_demo
    uri = Addressable::URI.parse('http://youtube.com/watch?v=test')

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
