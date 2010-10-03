require 'test/test_helper'

class MonitorTest < Test::Unit::TestCase
  class Deadpool::Monitor::AllUp < Deadpool::Monitor::Base
    def primary_ok?;   true; end
    def secondary_ok?; true; end
  end

  class Deadpool::Monitor::PrimaryDown < Deadpool::Monitor::Base
    def primary_ok?;   false; end
    def secondary_ok?; true; end
  end

  class Deadpool::Monitor::SecondaryDown < Deadpool::Monitor::Base
    def primary_ok?;   true; end
    def secondary_ok?; false; end
  end

  class Deadpool::Monitor::AllDown < Deadpool::Monitor::Base
    def primary_ok?;   false; end
    def secondary_ok?; false; end
  end

  def setup
    @config  = { :pool_name => "test.fake" }
    @logger  = Logger.new("/dev/null")
    @monitor = Deadpool::Monitor::AllUp.new(@config, @logger)
  end

  def test_state_name
    assert_equal "Deadpool::Monitor::AllUp - test.fake", @monitor.state.name
  end

  def test_system_check
    snapshot = Deadpool::Monitor::AllUp.new(@config, @logger).system_check
    assert_equal Deadpool::OK, snapshot.overall_status
    assert_match /Primary and Secondary are up/, snapshot.full_report

    snapshot = Deadpool::Monitor::PrimaryDown.new(@config, @logger).system_check
    assert_equal Deadpool::WARNING, snapshot.overall_status
    assert_match /Primary is down. Secondary is up/, snapshot.full_report

    snapshot = Deadpool::Monitor::SecondaryDown.new(@config, @logger).system_check
    assert_equal Deadpool::WARNING, snapshot.overall_status
    assert_match /Primary is up. Secondary is down/, snapshot.full_report

    snapshot = Deadpool::Monitor::AllDown.new(@config, @logger).system_check
    assert_equal Deadpool::CRITICAL, snapshot.overall_status
    assert_match /Primary and Secondary are down/, snapshot.full_report
  end
end