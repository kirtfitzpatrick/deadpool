require 'test_helper'

class HandlerTest < Test::Unit::TestCase

  class MockTimer

    def cancel; end

  end

  class Deadpool::Monitor::Mock < Deadpool::Monitor::Base

    def primary_ok?
      true
    end

    def secondary_ok?
      true
    end

  end

  class Deadpool::FailoverProtocol::Mock < Deadpool::FailoverProtocol::Base
  end

  def setup
    @config = {
      primary: 'localhost',
      secondary: '127.0.0.1',
      pool_name: 'test.fake',
      max_failed_checks: 2,
      monitor_config: { monitor_class: 'Mock' },
      failover_protocol_configs: [
        { protocol_class: 'Mock' }
      ]
    }
    @logger = Logger.new('/dev/null')
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
    assert @handler.state.error_messages.include?('Failover Protocol in place.')
  end

  def test_monitor_pool_with_too_many_failures_and_failed_failover
    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(false).twice
    Deadpool::FailoverProtocol::Mock.any_instance.expects(:initiate_failover_protocol!).returns(false)
    MockTimer.any_instance.expects(:cancel)

    assert_equal 2, @handler.max_failed_checks

    @handler.monitor_pool(MockTimer.new)
    assert_equal Deadpool::WARNING, @handler.state.status_code
    assert_equal 1, @handler.failure_count

    @handler.monitor_pool(MockTimer.new)

    assert_equal Deadpool::CRITICAL, @handler.state.status_code
    assert_equal 2, @handler.failure_count

    assert @handler.state.instance_eval { @locked }
    assert @handler.state.error_messages.include?('Failover Protocol Failed!')
  end

  def test_system_check_should_return_snapshot_of_state_monitor_and_failure_protocol_states
    assert_equal Deadpool::OK, @handler.system_check.overall_status

    Deadpool::Monitor::Mock.any_instance.expects(:primary_ok?).returns(false)
    assert_equal Deadpool::WARNING, @handler.system_check.overall_status
  end

  def test_promote_with_no_host
    assert !@handler.promote(nil)
  end

  def test_promote_with_failed_promotion
    Deadpool::FailoverProtocol::Mock.any_instance.expects(:promote_to_primary).returns(false)
    assert !@handler.promote(:secondary)
  end

  def test_promote_with_successful_promotion
    Deadpool::FailoverProtocol::Mock.any_instance.expects(:promote_to_primary).returns(true)
    assert @handler.promote(:secondary)
  end

end
