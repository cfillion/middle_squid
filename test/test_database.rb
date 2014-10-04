require File.expand_path '../helper', __FILE__

class TestDatabase < MiniTest::Test
  include MiddleSquid::Database

  def test_db
    assert_instance_of SQLite3::Database, db()
  end

  def test_setup
    before = db()
    refute before.closed?

    MiddleSquid::Database.setup ':memory:'

    after = db()
    refute_same before, after
    assert before.closed?, 'the old database should be closed'
  end
end
