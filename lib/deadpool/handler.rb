module Deadpool
  class Handler

    attr_accessor :logger
    attr_reader :state,
                :failure_count,
                :check_interval,
                :max_failed_checks,
                :pool_name,
                :primary,
                :secondary

    def initialize(config, logger)
      @config = config
      @logger = logger
      @pool_name = config[:pool_name]
      @check_interval = config[:check_interval]
      @max_failed_checks = config[:max_failed_checks]
      @primary = config[:primary]
      @secondary = config[:secondary]
      @failure_count = 0
      @state = Deadpool::State.new @pool_name, self.class.to_s
      instantiate_monitor
      instantiate_failover_protocols
      @state.set_state(OK, 'Handler initialized.')
    end

    def monitor_pool(timer)
      if @monitor.primary_ok?
        @failure_count = 0
        @state.set_state(OK, 'Primary Check OK.')
        logger.info "#{@pool_name} Primary Check Okay.  Failure Count set to 0."
      else
        @failure_count += 1
        @state.set_state(WARNING, "Primary Check failed #{@failure_count} times")
        logger.warn "#{@pool_name} Primary Check Failed.  Failure Count at #{@failure_count}"
      end

      if @failure_count >= @max_failed_checks
        timer.cancel
        @state.set_state(WARNING, 'Failure threshold exceeded.  Failover Protocol Initiated.')
        logger.error "#{@pool_name} primary is dead.  Initiating Failover Protocol."

        success = true
        @failover_protocols.each do |failover_protocol|
          success &&= failover_protocol.initiate_failover_protocol!
        end

        if success
          logger.warn 'Failover Protocol Finished.'
          @state.set_state(WARNING, 'Failover Protocol in place.')
          @state.lock
        else
          logger.error 'Failover Protocol Failed!'
          @state.set_state(CRITICAL, 'Failover Protocol Failed!')
          @state.lock
        end
      end
    end

    def system_check
      snapshot = Deadpool::StateSnapshot.new @state
      snapshot.add_child @monitor.system_check
      @failover_protocols.each do |failover_protocol|
        # logger.debug failover_protocol.inspect
        snapshot.add_child failover_protocol.system_check
      end

      snapshot
    end

    def promote(server)
      # This will stop at the first failure
      @config[server] && @failover_protocols.all? do |failover_protocol|
        logger.debug "Promote: server: #{server}"
        failover_protocol.promote_to_primary @config[server]
      end
    end

    protected

    def instantiate_monitor
      monitor_class = Deadpool::Monitor.const_get(@config[:monitor_config][:monitor_class])
      @monitor = monitor_class.new(@config, @config[:monitor_config], logger)
    end

    def instantiate_failover_protocols
      @failover_protocols = []
      @config[:failover_protocol_configs].each do |failover_config|
        failover_protocol_class = Deadpool::FailoverProtocol.const_get(failover_config[:protocol_class])
        @failover_protocols << failover_protocol_class.new(@config, failover_config, logger)
      end
    end

  end
end
