require File.expand_path '../helper', __FILE__

class TestDatabase < MiniTest::Test
  include MiddleSquid::Database

  make_my_diffs_pretty!

  def setup
    @path = File.expand_path '../resources', __FILE__
    MiddleSquid::BlackList.class_eval '@@instances.clear'

    db.execute 'BEGIN'

    db.execute 'DELETE FROM domains' 
    db.execute 'DELETE FROM urls' 

    db.execute 'INSERT INTO domains (category, host) VALUES (?, ?)',
      ['test', 'anidb.net']

    db.execute 'INSERT INTO urls (category, host, path) VALUES (?, ?, ?)',
      ['test', 'test.com', '/path']

    db.execute 'END'
  end

  def has_test_data?
    has_domain = !!db.get_first_row(
      "SELECT 1 FROM domains WHERE category = 'test' AND host = 'anidb.net' AND rowid = 1 LIMIT 1"
    )

    has_url = !!db.get_first_row(
      "SELECT 1 FROM urls WHERE category = 'test' AND host = 'test.com' AND path = '/path' AND rowid = 1 LIMIT 1"
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
      MiddleSquid::Database.build @path + '/black'
    end

    assert_equal "nothing to do in minimal indexing mode\n", stdout
    assert_match 'ERROR', stderr

    assert has_test_data?
  end

  def test_empty_rollback
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/empty'
    end

    assert_match 'indexing category/emptylist', stdout
    assert_match 'reverting changes', stdout
    assert_match 'WARNING: nothing to commit', stderr

    assert has_test_data?
  end

  def test_index
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/black'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['adv', 'ads.google.com'],
      ['adv', 'doubleclick.net'],
      ['tracker', 'xiti.com'],
      ['tracker', 'google-analytics.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['adv', 'google.com', '/adsense'],
      ['tracker', 'feedproxy.google.com', '/~r'],
      ['tracker', 'cloudfront-labs.amazonaws.com', '/x.png'],
    ], urls

    assert_match 'indexing adv/urls', stdout
    assert_match 'indexing adv/domains', stdout
    assert_match 'indexing tracker/urls', stdout
    assert_match 'indexing tracker/domains', stdout
    assert_match 'indexed 2 categorie(s): ["adv", "tracker"]', stdout
    assert_match 'found 4 domain(s)', stdout
    assert_match 'found 3 url(s)', stdout
    assert_match 'found 0 duplicate(s)', stdout
    assert_match 'committing changes', stdout
    assert_empty stderr
  end

  def test_ignore_subdirectories
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/subdirectory'
    end

    refute_match 'cat/ignore', stdout
    assert has_test_data?
  end

  def test_minimal_indexing
    MiddleSquid::Config.minimal_indexing = true
    MiddleSquid::BlackList.new 'adv'

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/black'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['adv', 'ads.google.com'],
      ['adv', 'doubleclick.net'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['adv', 'google.com', '/adsense'],
    ], urls

    refute_match 'tracker', stdout
    assert_match 'indexed 1 categorie(s): ["adv"]', stdout
    assert_empty stderr
  end

  def test_not_found
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/404'
    end

    assert_match "reading #{@path + '/404'}", stdout
    assert_match "WARNING: #{@path + '/404'}: no such directory\n", stderr
    assert_match "WARNING: nothing to commit", stderr
  end

  def test_mixed
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/mixed'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', 'domain.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', 'url.com', '/path'],
    ], urls
  end

  def test_backslash
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/backslash'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', 'google.com', '/path/to/file'],
    ], urls
  end

  def test_invalid_byte
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/invalid_byte'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_empty domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', 'host.com', '/path_with_3_invalid_byte'],
    ], urls
  end

  def test_normalize
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/normalize'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', 'host.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_empty urls
  end

  def test_duplicates
    MiddleSquid::Config.minimal_indexing = false

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/duplicates'
    end

    refute has_test_data?

    domains = db.execute 'SELECT category, host FROM domains'
    assert_equal [
      ['cat', 'host.com'],
      ['copy_of_cat', 'host.com'],
    ], domains

    urls = db.execute 'SELECT category, host, path FROM urls'
    assert_equal [
      ['cat', 'host.com', '/path'],
      ['copy_of_cat', 'host.com', '/path'],
    ], urls

    assert_match 'found 4 duplicate(s)', stdout
    assert_empty stderr
  end

  def test_missing_category
    MiddleSquid::Config.minimal_indexing = false
    MiddleSquid::BlackList.new '404'
    MiddleSquid::BlackList.new '404' # should not cause duplicate output

    stdout, stderr = capture_io do
      MiddleSquid::Database.build @path + '/black'
    end

    refute has_test_data?

    assert_match 'WARNING: could not find ["404"]', stderr
  end
end
