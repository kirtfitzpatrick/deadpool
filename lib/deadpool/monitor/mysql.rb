
module Deadpool
  
  module Monitor
    
    class Mysql

      attr_accessor :logger

      def initialize(config, logger)
        @state               = Deadpool::State.new "Deadpool::Monitor::Mysql - #{config[:pool_name]}"
        @config              = config
        @logger              = logger
        @nagios_plugins_path = config[:monitor_config][:nagios_plugin_path]
      end

      def primary_ok?
        return check_mysql @config[:primary_host]
      end

      def secondary_ok?        
        return (check_mysql @config[:secondary_host] and
            check_mysql_slave @config[:secondary_host])
      end

      def system_check
        primary_okay   = primary_ok?
        secondary_okay = secondary_ok?

        if primary_okay and secondary_okay
          @state.set_state OK, "Primary and Secondary are up."
        elsif !primary_okay and secondary_okay
          @state.set_state WARNING, "Primary is down.  Secondary is up."
        elsif primary_okay and !secondary_okay
          @state.set_state WARNING, "Primary is up.  Secondary is down."
        else
          @state.set_state CRITICAL, "Primary and Secondary are down."
        end
        
        return Deadpool::StateSnapshot.new @state
      end


      protected

      def check_mysql(host)
        check_mysql_plugin = File.join @nagios_plugins_path, 'check_mysql'
        check_command      = "#{check_mysql_plugin} -H #{host} -u monitor -p 'M0n1t0r'"
        logger.debug check_command
        status_message     = `#{check_command}`
        exit_status        = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status == 0
      end
      
      def check_mysql_slave(host)
        check_mysql_slave_plugin = File.join @nagios_plugins_path, 'check_mysql'
        check_command            = "#{check_mysql_slave_plugin} -H #{host} -u monitor -p 'M0n1t0r' --check-slave"
        logger.debug check_command
        status_message           = `#{check_command}`
        exit_status              = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status
      end
      
    end

  end

end

