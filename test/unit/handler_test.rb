require 'test/test_helper'

class HandlerTest < Test::Unit::TestCase

  class MockTimer
    def cancel; end
  end

  class Deadpool::Monitor::Mock < Deadpool::Monitor::Base
  end

  class Deadpool::FailoverProtocol::Mock < Deadpool::FailoverProtocol::Base
  end

  def setup
    @config = {
      :pool_name => "test.fake",
      :max_failed_checks => 2,
      :monitor_config => { :monitor_class => "Mock" },
      :failover_protocol_configs => [
        { :protocol_class => "Mock" }
      ]
    }

    @logger = Logger.new("/dev/null")

    @handler = Deadpool::Handler.new(@config, @logger)
  end

  def test_monitor_instantiation
    assert_instance_of Deadpool::Monitor::Mock, @handler.instance_eval { @monitor }
  end

  def test_failover_protocal_instantiation
    assert_instance_of Deadpool::FailoverProtocol::Mock, @handler.instance_eval { @failover_protocols }.first
  end

  def test_monitor_pool_with_normal_primary
    monitor = @handler.instance_eval { @monitor }
    monitor.expects(:primary_ok?).returns(true)

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::OK, @handler.state.status_code
    assert_equal 0, @handler.failure_count
  end

  def test_monitor_pool_with_failing_primary
    monitor = @handler.instance_eval { @monitor }
    monitor.expects(:primary_ok?).returns(false)

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 1, @handler.failure_count
  end
end