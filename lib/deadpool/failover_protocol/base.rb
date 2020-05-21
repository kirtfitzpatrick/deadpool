module Deadpool
  module FailoverProtocol
    class Base

      attr_reader :logger
      attr_reader :config

      def initialize(config, failover_config, logger)
        @state = Deadpool::State.new failover_config[:name], self.class.to_s
        @config = config
        @failover_config = failover_config
        @logger = logger
        @primary = @config[:primary]
        @secondary = @config[:secondary]
        setup
      end

      # Implementation specific initialization should be placed here.
      def setup; end

      # Overwrite this if you need to.
      # Update state to reflect that failover has been initiated.
      # State must be updated to no less than WARNING.
      # State must be CRITICAL if any step of the protocol fails.
      # Lock the state at whatever stage the failover reached.
      # return true or false on success or failure.
      #
      def initiate_failover_protocol!
        logger.info 'Performing Preflight Check'
        @state.set_state WARNING, 'Failover Protocol Initiated.'

        if preflight_check
          logger.info 'Preflight Check Passed.'
          @state.add_message 'Preflight Check Passed.'
        else
          logger.error 'Preflight Check Failed!  Aborting Failover Protocol.'
          @state.escalate_status_code CRITICAL
          @state.add_error_message 'Preflight Check Failed! Failover Protocol Aborted!'
          @state.lock
          return false
        end

        if promote_to_primary(@secondary)
          logger.info "#{@secondary} successfully promoted to primary"
          @state.add_message 'Failover Protocol Successful.'
          @state.lock
          true
        else
          logger.info "#{@secondary} promotion failed."
          @state.escalate_status_code CRITICAL
          @state.add_error_message 'Failover Protocol Failed!'
          @state.lock
          false
        end
      end

      # Return true or false
      # Don't update system state.
      # return true or false success or failure
      def preflight_check
        false
      end

      # Promote the host to primary.  This is used by initiate_failover_protocol!
      # and for manual promotion by an administrator.
      # new_primary is an IP address
      # TODO: change new_primary to be a config label.
      # return true or false success or failure
      def promote_to_primary(_new_primary)
        false
      end

      # Perform checks against anything that could cause a failover protocol to fail
      # Perform checks on system state.
      # return New Deadpool::StateSnapshot
      def system_check
        Deadpool::StateSnapshot.new @state
      end

    end
  end
end
