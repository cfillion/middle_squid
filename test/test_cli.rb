require File.expand_path '../helper', __FILE__

class TestCLI < MiniTest::Test
  def test_exec
    path = File.expand_path '../resources', __FILE__
    conf = path + '/hello.rb'

    stdout, stderr = capture_io do
      MiddleSquid::CLI.start(%W[exec -C #{conf}])
    end

    assert_match /\Ahello #<MiddleSquid:.+>\Z/, stdout

    if STDOUT.tty?
      assert_match /should be launched from squid/i, stderr
    else
      assert_empty stderr
    end
  end

  def test_exec_missing_config
    stdout, stderr = capture_io do
      MiddleSquid::CLI.start %w[exec]
    end

    assert_empty stdout
    assert_match /no value provided for required options/i, stderr
  end

  def test_build
    MiddleSquid::Config.minimal_indexing = false

    path = File.expand_path '../resources', __FILE__
    conf = path + '/hello.rb'
    list = path + '/black'

    stdout, stderr = capture_io do
      MiddleSquid::CLI.start(%W[build #{list} -C #{conf}])
    end

    assert_match /\Ahello #<MiddleSquid:.+>$/, stdout
    assert_match "reading #{list}", stdout
  end

  def test_version
    stdout, stderr = capture_io do
      MiddleSquid::CLI.start %w[version]
    end

    assert_match /MiddleSquid #{MiddleSquid::VERSION}/, stdout
    assert_match /Copyright/, stdout
    assert_match /GNU General Public License/, stdout
    assert_match /version 3/, stdout
    assert_empty stderr
  end

  def test_help
    stdout, stderr = capture_io do
      MiddleSquid::CLI.start %w[--help]
    end

    assert_match /Commands:/, stdout
    assert_match /Options:/, stdout
    assert_empty stderr
  end
end
