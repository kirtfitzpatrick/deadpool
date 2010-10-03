module Deadpool
  module Monitor
    class Base
      attr_accessor :logger

      def initialize(config, logger)
        @config, @logger = config, logger
      end

      def primary_ok?
        raise NotImplementedError, "primary_ok? is not implemented"
      end

      def secondary_ok?
        raise NotImplementedError, "secondary_ok? is not implemented"
      end

      def system_check
        update_state
        take_snapshot
      end

      def state
        @state ||= State.new(deadpool_state_name)
      end

      protected

      def update_state
        args = case [ primary_ok?, secondary_ok? ]
        when [true, true]
          [ OK, "Primary and Secondary are up." ]
        when [false, true]
          [ WARNING, "Primary is down. Secondary is up." ]
        when [true, false]
          [ WARNING, "Primary is up. Secondary is down." ]
        else
          [ CRITICAL, "Primary and Secondary are down." ]
        end

        self.state.set_state(*args)
      end

      def take_snapshot
        StateSnapshot.new(self.state)
      end

      def deadpool_state_name
        "%s - %s" % [ self.class.name, @config[:pool_name] ]
      end
    end
  end
end
