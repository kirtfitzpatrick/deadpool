module Deadpool
  module Monitor
    class Base

      attr_accessor :logger

      def initialize(config, monitor_config, logger)
        @config = config
        @monitor_config = monitor_config
        @logger = logger
      end

      def primary_ok?
        raise NotImplementedError, 'primary_ok? is not implemented'
      end

      def secondary_ok?
        raise NotImplementedError, 'secondary_ok? is not implemented'
      end

      def system_check
        update_state
        take_snapshot
      end

      def state
        @state ||= Deadpool::State.new name, self.class.to_s
      end

      protected

      def update_state
        primary_okay = primary_ok?
        secondary_okay = secondary_ok?
        logger.debug "PrimaryOkay? #{primary_okay}, SecondaryOkay? #{secondary_okay}"

        args = case [primary_okay, secondary_okay]
               when [true, true]
                 [OK, 'Primary and Secondary are up.']
               when [false, true]
                 [WARNING, 'Primary is down. Secondary is up.']
               when [true, false]
                 [WARNING, 'Primary is up. Secondary is down.']
               when [false, false]
                 [CRITICAL, 'Primary and Secondary are down.']
               else
                 [CRITICAL, 'Implementation Error.']
        end

        state.set_state(*args)
      end

      def take_snapshot
        StateSnapshot.new(state)
      end

      def name
        @monitor_config[:name].nil? ? nil : @monitor_config[:name]
      end

    end
  end
end
