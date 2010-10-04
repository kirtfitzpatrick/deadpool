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
    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(true)

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::OK, @handler.state.status_code
    assert_equal 0, @handler.failure_count
    assert !@handler.state.instance_eval { @locked }
  end

  def test_monitor_pool_with_failing_primary
    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(false)

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 1, @handler.failure_count
    assert !@handler.state.instance_eval { @locked }
  end

  def test_monitor_pool_with_too_many_failures_and_successful_failover
    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(false).twice
    Deadpool::FailoverProtocol::Mock.any_instance.expects(:initiate_failover_protocol!).returns(true)

    assert_equal 2, @handler.max_failed_checks

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 1, @handler.failure_count

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 2, @handler.failure_count

    assert @handler.state.instance_eval { @locked }
    assert @handler.state.error_messages.include?("Failover Protocol in place.")
  end

  def test_monitor_pool_with_too_many_failures_and_failed_failover
    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(false).twice
    Deadpool::FailoverProtocol::Mock.any_instance.expects(:"initiate_failover_protocol!").returns(false)
    MockTimer.any_instance.expects(:cancel)

    assert_equal 2, @handler.max_failed_checks

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 1, @handler.failure_count

    @handler.monitor_pool(MockTimer.new)

    assert_equal Deadpool::CRITICAL, @handler.state.status_code
    assert_equal 2, @handler.failure_count

    assert @handler.state.instance_eval { @locked }
    assert @handler.state.error_messages.include?("Failover Protocol Failed!")
  end

end