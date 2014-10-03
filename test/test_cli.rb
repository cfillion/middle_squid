require File.expand_path '../helper', __FILE__

class TestCLI < MiniTest::Test
  def test_start
    path = File.expand_path '../resources', __FILE__
    conf = File.join path, 'hello.rb'

    stdout, stderr = capture_io do
      EM.run {
        MiddleSquid::CLI.start(%W[start -C #{conf}])
        EM.next_tick { EM.stop }
      }
    end

    assert_match /\Ahello #<MiddleSquid:.+>\Z/, stdout
  end

  def test_start_relative
    absolute = File.expand_path '../resources', __FILE__
    path = Pathname.new(absolute).relative_path_from(Pathname.new(Dir.home))

    conf = File.join '~', path, 'hello.rb'

    capture_io do
      EM.run {
        MiddleSquid::CLI.start(%W[start -C #{conf}])
        EM.next_tick { EM.stop }
      }
    end
  end

  def test_start_missing_config
    stdout, stderr = capture_io do
      MiddleSquid::CLI.start %w[start]
    end

    assert_empty stdout
    assert_match /no value provided for required options/i, stderr
  end

  def test_index
    path = File.expand_path '../resources', __FILE__
    conf = File.join path, 'hello.rb'
    list = File.join path, 'black'

    stdout, stderr = capture_io do
      MiddleSquid::CLI.start(%W[index #{list} -C #{conf} --full])
    end

    assert_match /\Ahello #<MiddleSquid:.+>$/, stdout
    assert_match "reading #{list}", stdout
  end

  def test_index_relative_path
    absolute = File.expand_path '../resources', __FILE__
    path = Pathname.new(absolute).relative_path_from(Pathname.new(Dir.home))

    conf = File.join '~', path, 'hello.rb'
    list = File.join '~', path, 'black'

    stdout, stderr = capture_io do
      MiddleSquid::CLI.start(%W[index #{list} -C #{conf} --full])
    end

    assert_match /\Ahello #<MiddleSquid:.+>$/, stdout
    assert_match "reading #{absolute}/black", stdout
  end

  def test_index_multiple
    path = File.expand_path '../resources', __FILE__
    config = File.join path, 'hello.rb'
    list_1 = File.join path, 'black'
    list_2 = File.join path, 'gray'

    stdout, stderr = capture_io do
      MiddleSquid::CLI.start(%W[index #{list_1} #{list_2} -C #{config} --full])
    end

    assert_match "reading #{list_1}", stdout
    assert_match "reading #{list_2}", stdout
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
