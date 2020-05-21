require 'test_helper'

class MonitorTest < Test::Unit::TestCase

  class Deadpool::Monitor::AllUp < Deadpool::Monitor::Base

    def primary_ok?
      true
    end

    def secondary_ok?
      true
    end

  end

  class Deadpool::Monitor::PrimaryDown < Deadpool::Monitor::Base

    def primary_ok?
      false
    end

    def secondary_ok?
      true
    end

  end

  class Deadpool::Monitor::SecondaryDown < Deadpool::Monitor::Base

    def primary_ok?
      true
    end

    def secondary_ok?
      false
    end

  end

  class Deadpool::Monitor::AllDown < Deadpool::Monitor::Base

    def primary_ok?
      false
    end

    def secondary_ok?
      false
    end

  end

  def setup
    @config = { pool_name: 'test.fake' }
    @monitor_config = { name: 'test.monitor.fake' }
    @logger = Logger.new('/dev/null')
  end

  def test_state_name
    state_name = Deadpool::Monitor::AllUp.new(@config, @monitor_config, @logger).state.name
    assert_equal('test.monitor.fake - Deadpool::Monitor::AllUp', state_name)
  end

  def test_system_check_up_up
    snapshot = Deadpool::Monitor::AllUp.new(@config, @monitor_config, @logger).system_check
    assert_equal(Deadpool::OK, snapshot.overall_status)
    assert_match(/Primary and Secondary are up/, snapshot.full_report)
  end

  def test_system_check_down_up
    snapshot = Deadpool::Monitor::PrimaryDown.new(@config, @monitor_config, @logger).system_check
    assert_equal(Deadpool::WARNING, snapshot.overall_status)
    assert_match(/Primary is down. Secondary is up/, snapshot.full_report)
  end

  def test_system_check_up_down
    snapshot = Deadpool::Monitor::SecondaryDown.new(@config, @monitor_config, @logger).system_check
    assert_equal(Deadpool::WARNING, snapshot.overall_status)
    assert_match(/Primary is up. Secondary is down/, snapshot.full_report)
  end

  def test_system_check_down_down
    snapshot = Deadpool::Monitor::AllDown.new(@config, @monitor_config, @logger).system_check
    assert_equal(Deadpool::CRITICAL, snapshot.overall_status)
    assert_match(/Primary and Secondary are down/, snapshot.full_report)
  end

end
