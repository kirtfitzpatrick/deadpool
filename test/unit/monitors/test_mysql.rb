
require 'test/test_helper'


class TestDeadpoolMonitorMysql < Test::Unit::TestCase
  
  def setup
    config_file       = File.join(File.expand_path('../../..', __FILE__), 'fixtures/mysql.yml')
    @config           = YAML.load(File.read(config_file))
    # @monitor_config = @config['monitor_config']
    @logger           = Logger.new(STDOUT)
    @logger.level     = Logger::DEBUG
    @mysql            = Deadpool::Monitor::Mysql.new @config, @logger
  end
  
  def teardown
  end
  
  def test_primary_ok?
    assert(@mysql.primary_ok?, "Primary Okay.")
  end

  def test_secondary_ok?
    assert(@mysql.secondary_ok?, "Secondary Okay.")
  end

end
