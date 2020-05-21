require 'test_helper'

class FailoverProtocolTest < Test::Unit::TestCase

  class Deadpool::FailoverProtocol::Mock < Deadpool::FailoverProtocol::Base
  end

  def setup
    config = { pool_name: 'test.pool.fake' }
    failover_config = { name: 'test.failover.fake' }
    logger = Logger.new('/dev/null')

    @failover = Deadpool::FailoverProtocol::Mock.new(config, failover_config, logger)
  end

  def test_initial_state
    assert_equal 'test.failover.fake - Deadpool::FailoverProtocol::Mock', @failover.instance_eval { @state }.name
  end

  def test_system_check
    assert_instance_of Deadpool::StateSnapshot, @failover.system_check
  end

  def test_successful_failover
    @failover.expects(:preflight_check).returns(true)
    @failover.expects(:promote_to_primary).returns(true)

    assert @failover.initiate_failover_protocol!

    assert_locked
    assert_status Deadpool::WARNING
  end

  def test_failure_on_preflight_check
    @failover.expects(:preflight_check).returns(false)
    @failover.expects(:promote_to_primary).never

    assert !@failover.initiate_failover_protocol!

    assert_locked
    assert_status Deadpool::CRITICAL
  end

  def test_failure_on_promotion_to_primary
    @failover.expects(:preflight_check).returns(true)
    @failover.expects(:promote_to_primary).returns(false)

    assert !@failover.initiate_failover_protocol!

    assert_locked
    assert_status Deadpool::CRITICAL
  end

  # Custom assertions

  def assert_locked
    state = @failover.instance_eval { @state }
    assert state.instance_eval { @locked }
  end

  def assert_status(status_code)
    assert_equal status_code, @failover.system_check.overall_status
  end

end
