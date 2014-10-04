require File.expand_path '../helper', __FILE__

class TestIndexer < MiniTest::Test
  include MiddleSquid::Database

  make_my_diffs_pretty!

  def setup
    @obj = MiddleSquid::Indexer.new
    @path = File.expand_path '../resources', __FILE__

    db.transaction

    db.execute 'DELETE FROM domains' 
    db.execute 'DELETE FROM urls' 

    db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
      ['test', '.anidb.net']

    db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
      ['test', '.test.com', 'path']

    db.commit
  end

  def has_test_data?
    has_domain = !!db.get_first_row(
      "SELECT 1 FROM domains WHERE category = 'test' AND host = '.anidb.net' AND rowid = 1 LIMIT 1"
    )

    has_url = !!db.get_first_row(
      "SELECT 1 FROM urls WHERE category = 'test' AND host = '.test.com' AND path = 'path/' AND rowid = 1 LIMIT 1"
    )

    has_domain || has_url
  end

  def test_minimal_no_blacklist_used
    @obj.full_index = false

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    assert_equal "nothing to do in minimal indexing mode\n", stdout

    assert_match 'ERROR', stderr

    assert has_test_data?
  end

  def test_empty_rollback
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'empty')]
    end

    assert_match 'indexing cat/emptylist', stdout
    assert_match 'reverting changes', stdout

    assert_match 'ERROR: nothing to commit', stderr

    assert has_test_data?
  end

  def test_full_index
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['ads', '.ads.google.com'],
      ['ads', '.doubleclick.net'],
      ['tracker', '.xiti.com'],
      ['tracker', '.google-analytics.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense/'],
      ['tracker', '.feedproxy.google.com', '~r/'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png/'],
    ], urls

    assert_match 'indexing ads/urls', stdout
    assert_match 'indexing ads/domains', stdout
    assert_match 'indexing tracker/urls', stdout
    assert_match 'indexing tracker/domains', stdout
    assert_match 'indexed 2 categorie(s): ["ads", "tracker"]', stdout
    assert_match 'found 4 domain(s)', stdout
    assert_match 'found 3 url(s)', stdout
    assert_match 'found 0 duplicate(s)', stdout
    assert_match 'found 0 ignored expression(s)', stdout
    assert_match 'committing changes', stdout

    assert_empty stderr
  end

  def test_index_multiple
    stdout, stderr = capture_io do
      @obj.index [
        File.join(@path, 'black'),
        File.join(@path, 'gray'),
      ]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['ads', '.ads.google.com'],
      ['ads', '.doubleclick.net'],
      ['tracker', '.xiti.com'],
      ['tracker', '.google-analytics.com'],
      ['isp', '.000webhost.com'],
      ['isp', '.comcast.com'],
      ['news', '.reddit.com'],
      ['news', '.news.ycombinator.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense/'],
      ['tracker', '.feedproxy.google.com', '~r/'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png/'],
      ['isp', '.telus.com', 'content/internet/'],
    ], urls

    assert_match 'indexed 4 categorie(s): ["ads", "tracker", "isp", "news"]', stdout
    assert_match 'found 8 domain(s)', stdout
    assert_match 'found 4 url(s)', stdout
    assert_match 'found 0 duplicate(s)', stdout

    assert_empty stderr
  end

  def test_ignore_subdirectories
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'subdirectory')]
    end

    refute_match 'cat/ignore', stdout
    assert has_test_data?
  end

  def test_minimal_indexing
    @obj.blacklists = [MiddleSquid::BlackList.new('ads')]
    @obj.full_index = false

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['ads', '.ads.google.com'],
      ['ads', '.doubleclick.net'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense/'],
    ], urls

    refute_match 'tracker', stdout
    assert_match 'indexed 1 categorie(s): ["ads"]', stdout

    assert_empty stderr
  end

  def test_not_found
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, '404')]
    end

    assert has_test_data?

    assert_match "reading #{File.join @path, '404'}", stdout

    assert_match "WARNING: #{File.join @path, '404'}: no such directory\n", stderr
    assert_match "ERROR: nothing to commit", stderr
  end

  def test_multiple_not_found
    stdout, stderr = capture_io do
      @obj.index [
        File.join(@path, '404'),
        File.join(@path, 'gray'),
      ]
    end

    refute has_test_data?

    assert_match "reading #{File.join @path, '404'}", stdout
    assert_match "reading #{File.join @path, 'gray'}", stdout

    assert_match "WARNING: #{File.join @path, '404'}: no such directory\n", stderr
  end

  def test_mixed_content
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'mixed')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', '.domain.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.url.com', 'path/'],
    ], urls
  end

  def test_backslash
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'backslash')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.google.com', 'path/to/file/'],
    ], urls
  end

  def test_invalid_byte
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'invalid_byte')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.host.com', 'path_with__invalid_byte/'],
    ], urls
  end

  def test_empty_path_as_domain
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'empty_path')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', '.host.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_empty urls
  end

  def test_duplicates
    stdout, stderr = capture_io do
      @obj.index [
        File.join(@path, 'duplicates'),
        File.join(@path, 'copy_of_duplicates'),
      ]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', '.host.com'],
      ['copy_of_cat', '.host.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.host.com', 'path/'],
      ['copy_of_cat', '.host.com', 'path/'],
    ], urls

    assert_match 'found 12 duplicate(s)', stdout
    assert_match 'found 0 ignored expression(s)', stdout

    assert_empty stderr
  end

  def test_missing_category
    bl = MiddleSquid::BlackList.new '404'
    @obj.blacklists = [bl, bl] # should not cause duplicate output

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    assert_match 'WARNING: could not find ["404"]', stderr
  end

  def test_expressions
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'expressions')]
    end

    assert has_test_data?

    assert_match 'found 3 ignored expression(s)', stdout
    assert_match 'ERROR: nothing to commit', stderr
  end

  def test_aliases
    @obj.full_index = false
    @obj.blacklists = [
      MiddleSquid::BlackList.new('cat_name', aliases: ['ads'])
    ]

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat_name', '.ads.google.com'],
      ['cat_name', '.doubleclick.net'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat_name', '.google.com', 'adsense/'],
    ], urls

    refute_match 'tracker', stdout
    assert_match 'indexing ads/', stdout
    assert_match 'indexed 1 categorie(s): ["cat_name"]', stdout

    assert_empty stderr
  end

  def test_domains_only
    @obj.entries = [:domain]

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['ads', '.ads.google.com'],
      ['ads', '.doubleclick.net'],
      ['tracker', '.xiti.com'],
      ['tracker', '.google-analytics.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_empty urls

    assert_match 'found 4 domain(s)', stdout
    assert_match 'found 0 url(s)', stdout
    assert_match 'found 3 ignored expression(s)', stdout

    assert_empty stderr
  end

  def test_urls_only
    @obj.entries = [:url]

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense/'],
      ['tracker', '.feedproxy.google.com', '~r/'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png/'],
    ], urls

    assert_match 'found 0 domain(s)', stdout
    assert_match 'found 3 url(s)', stdout
    assert_match 'found 4 ignored expression(s)', stdout

    assert_empty stderr
  end

  def test_append
    @obj.append = true

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    assert has_test_data?, 'should not be truncated'
    refute_match 'truncating', stdout

    assert_match 'found 4 domain(s)', stdout
    assert_match 'found 3 url(s)', stdout
  end

  def test_quiet
    @obj.quiet = true

    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'black')]
    end

    assert_empty stdout
    assert_empty stderr
  end

  def test_quiet_errors
    @obj.quiet = true

    stdout, stderr = capture_io do
      @obj.index []
    end

    assert_empty stdout
    assert_match 'nothing to commit', stderr
  end

  def test_strip_spaces
    stdout, stderr = capture_io do
      @obj.index [File.join(@path, 'trailing_space')]
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.before.com', 'path/'],
      ['cat', '.after.com', 'path/'],
    ], urls
  end
end
