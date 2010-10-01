


module Deadpool

  module FailoverProtocol

    class Base

      attr_accessor :logger
      attr_reader :config

      def initialize(config, failover_config, logger)
        @state           = Deadpool::State.new "#{self.class.to_s} - #{config[:pool_name]}"
        @config          = config
        @logger          = logger
        @primary_host    = @config[:primary_host]
        @secondary_host  = @config[:secondary_host]
        @failover_config = failover_config
        @name            = @failover_config[:name]
        setup
      end

      # Implementation specific initialization should be placed here.
      def setup
      end

      # Overwrite this if you need to.
      # Update state to reflect that failover has been initiated.
      # State must be updated to no less than WARNING.
      # State must be CRITICAL if any step of the protocol fails.
      # Lock the state at whatever stage the failover reached.
      # return true or false on success or failure.
      # 
      def initiate_failover_protocol!
        logger.info "Performing Preflight Check"
        @state.set_state WARNING, "Failover Protocol Initiated."

        if preflight_check
          logger.info "Preflight Check Passed."
          @state.add_message "Preflight Check Passed."
        else
          logger.error "Preflight Check Failed!  Aborting Failover Protocol."
          @state.escalate_status_code CRITICAL
          @state.add_error_message "Preflight Check Failed! Failover Protocol Aborted!"
          @state.lock
          return false
        end

        if promote_to_primary(@secondary_host)
          logger.info "#{@secondary_host} successfully promoted to primary"
          @state.add_message "Failover Protocol Successful."
          @state.lock
          return true
        else
          logger.info "#{@secondary_host} promotion failed."
          @state.escalate_status_code CRITICAL
          @state.add_error_message "Failover Protocol Failed!"
          @state.lock
          return false
        end
      end

      # Return true or false
      # Don't update system state.
      # return true or false success or failure
      def preflight_check
        return false
      end

      # Promote the host to primary.  This is used by initiate_failover_protocol!
      # and for manual promotion by an administrator.
      # new_primary is an IP address
      # TODO: change new_primary to be a config label.
      # return true or false success or failure
      def promote_to_primary(new_primary)
        return false
      end

      # Perform checks against anything that could cause a failover protocol to fail
      # Perform checks on system state.
      # return New Deadpool::StateSnapshot
      def system_check
        return Deadpool::StateSnapshot.new @state
      end

    end

  end

end
