require 'test/test_helper'

class FailoverProtocolTest < Test::Unit::TestCase
  class Deadpool::FailoverProtocol::Mock < Deadpool::FailoverProtocol::Base
  end

  def setup
    config          = { :pool_name => "test.fake" }
    failover_config = {}
    logger          = Logger.new("/dev/null")

    @failover = Deadpool::FailoverProtocol::Mock.new(config, failover_config, logger)
  end

  def test_initial_state
    assert_equal "Deadpool::FailoverProtocol::Mock - test.fake", @failover.instance_eval { @state }.name
  end

  def test_system_check
    assert_instance_of Deadpool::StateSnapshot, @failover.system_check
  end

  # # Overwrite this if you need to.
  # # Update state to reflect that failover has been initiated.
  # # State must be updated to no less than WARNING.
  # # State must be CRITICAL if any step of the protocol fails.
  # # Lock the state at whatever stage the failover reached.
  # # return true or false on success or failure.
  # # 
  # def initiate_failover_protocol!
  #   logger.info "Performing Preflight Check"
  #   @state.set_state WARNING, "Failover Protocol Initiated."
  # 
  #   if preflight_check
  #     logger.info "Preflight Check Passed."
  #     @state.add_message "Preflight Check Passed."
  #   else
  #     logger.error "Preflight Check Failed!  Aborting Failover Protocol."
  #     @state.escalate_status_code CRITICAL
  #     @state.add_error_message "Preflight Check Failed! Failover Protocol Aborted!"
  #     @state.lock
  #     return false
  #   end
  # 
  #   if promote_to_primary(@secondary_host)
  #     logger.info "#{@secondary_host} successfully promoted to primary"
  #     @state.add_message "Failover Protocol Successful."
  #     @state.lock
  #     return true
  #   else
  #     logger.info "#{@secondary_host} promotion failed."
  #     @state.escalate_status_code CRITICAL
  #     @state.add_error_message "Failover Protocol Failed!"
  #     @state.lock
  #     return false
  #   end
  # end

  def test_successful_failover
    @failover.expects(:preflight_check).returns(true)
    @failover.expects(:promote_to_primary).returns(true)
    assert @failover.initiate_failover_protocol!

    state = @failover.instance_eval { @state }
    assert state.instance_eval { @locked }
    assert_equal Deadpool::WARNING, state.status_code
  end
end