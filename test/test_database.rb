require File.expand_path '../helper', __FILE__

class TestDatabase < MiniTest::Test
  include MiddleSquid::Database

  make_my_diffs_pretty!

  def setup
    @path = File.expand_path '../resources', __FILE__

    db.transaction

    db.execute 'DELETE FROM domains' 
    db.execute 'DELETE FROM urls' 

    db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
      ['test', '.anidb.net']

    db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
      ['test', '.test.com', 'path']

    db.commit

    MiddleSquid::Config.minimal_indexing = false
    MiddleSquid::Config.index_entries = [:domain, :url]
  end

  def teardown
    MiddleSquid::BlackList.class_eval '@@instances.clear'
  end

  def has_test_data?
    has_domain = !!db.get_first_row(
      "SELECT 1 FROM domains WHERE category = 'test' AND host = '.anidb.net' AND rowid = 1 LIMIT 1"
    )

    has_url = !!db.get_first_row(
      "SELECT 1 FROM urls WHERE category = 'test' AND host = '.test.com' AND path = 'path' AND rowid = 1 LIMIT 1"
    )

    has_domain || has_url
  end

  def test_reuse
    MiddleSquid::Database.setup
    first = db()

    MiddleSquid::Database.setup
    second = db()

    assert_same first, second
  end

  def test_automatic_setup
    MiddleSquid::Database.class_eval '@@db = nil'
    assert_instance_of SQLite3::Database, db()
  end

  def test_minimal_no_blacklist_used
    MiddleSquid::Config.minimal_indexing = true

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
    end

    assert_equal "nothing to do in minimal indexing mode\n", stdout

    assert_match 'ERROR', stderr

    assert has_test_data?
  end

  def test_empty_rollback
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'empty')
    end

    assert_match 'indexing category/emptylist', stdout
    assert_match 'reverting changes', stdout

    assert_match 'WARNING: nothing to commit', stderr

    assert has_test_data?
  end

  def test_index
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
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
      ['ads', '.google.com', 'adsense'],
      ['tracker', '.feedproxy.google.com', '~r'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png'],
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
      MiddleSquid::Database.build \
        File.join(@path, 'black'), File.join(@path, 'gray')
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
      ['ads', '.google.com', 'adsense'],
      ['tracker', '.feedproxy.google.com', '~r'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png'],
      ['isp', '.telus.com', 'content/internet'],
    ], urls

    assert_match 'indexed 4 categorie(s): ["ads", "tracker", "isp", "news"]', stdout
    assert_match 'found 8 domain(s)', stdout
    assert_match 'found 4 url(s)', stdout
    assert_match 'found 0 duplicate(s)', stdout

    assert_empty stderr
  end

  def test_ignore_subdirectories
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'subdirectory')
    end

    refute_match 'cat/ignore', stdout
    assert has_test_data?
  end

  def test_minimal_indexing
    MiddleSquid::Config.minimal_indexing = true
    MiddleSquid::BlackList.new 'ads'

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['ads', '.ads.google.com'],
      ['ads', '.doubleclick.net'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense'],
    ], urls

    refute_match 'tracker', stdout
    assert_match 'indexed 1 categorie(s): ["ads"]', stdout

    assert_empty stderr
  end

  def test_not_found
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, '404')
    end

    assert has_test_data?

    assert_match "reading #{File.join @path, '404'}", stdout

    assert_match "WARNING: #{File.join @path, '404'}: no such directory\n", stderr
    assert_match "WARNING: nothing to commit", stderr
  end

  def test_multiple_not_found
    stdout, stderr = capture_io do
      MiddleSquid::Database.build \
        File.join(@path, '404'),
        File.join(@path, 'gray')
    end

    refute has_test_data?

    assert_match "reading #{File.join @path, '404'}", stdout
    assert_match "reading #{File.join @path, 'gray'}", stdout

    assert_match "WARNING: #{File.join @path, '404'}: no such directory\n", stderr
  end

  def test_mixed_content
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'mixed')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', '.domain.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.url.com', 'path'],
    ], urls
  end

  def test_backslash
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'backslash')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.google.com', 'path/to/file'],
    ], urls
  end

  def test_invalid_byte
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'invalid_byte')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.host.com', 'path_with__invalid_byte'],
    ], urls
  end

  def test_empty_path_as_domain
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'empty_path')
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
      MiddleSquid::Database.build \
        File.join(@path, 'duplicates'),
        File.join(@path, 'copy_of_duplicates')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', '.host.com'],
      ['copy_of_cat', '.host.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', '.host.com', 'path'],
      ['copy_of_cat', '.host.com', 'path'],
    ], urls

    assert_match 'found 12 duplicate(s)', stdout
    assert_match 'found 0 ignored expression(s)', stdout

    assert_empty stderr
  end

  def test_missing_category
    MiddleSquid::BlackList.new '404'
    MiddleSquid::BlackList.new '404' # should not cause duplicate output

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
    end

    refute has_test_data?

    assert_match 'WARNING: could not find ["404"]', stderr
  end

  def test_expressions
    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'expressions')
    end

    assert has_test_data?

    assert_match 'found 3 ignored expression(s)', stdout
    assert_match 'WARNING: nothing to commit', stderr
  end

  def test_aliases
    MiddleSquid::Config.minimal_indexing = true
    MiddleSquid::BlackList.new 'cat_name', aliases: ['ads']

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat_name', '.ads.google.com'],
      ['cat_name', '.doubleclick.net'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat_name', '.google.com', 'adsense'],
    ], urls

    refute_match 'tracker', stdout
    assert_match 'indexing ads/', stdout
    assert_match 'indexed 1 categorie(s): ["cat_name"]', stdout

    assert_empty stderr
  end

  def test_domains_only
    MiddleSquid::Config.index_entries = [:domain]

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
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
    MiddleSquid::Config.index_entries = [:url]

    stdout, stderr = capture_io do
      MiddleSquid::Database.build File.join(@path, 'black')
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['ads', '.google.com', 'adsense'],
      ['tracker', '.feedproxy.google.com', '~r'],
      ['tracker', '.cloudfront-labs.amazonaws.com', 'x.png'],
    ], urls

    assert_match 'found 0 domain(s)', stdout
    assert_match 'found 3 url(s)', stdout
    assert_match 'found 4 ignored expression(s)', stdout

    assert_empty stderr
  end
end
