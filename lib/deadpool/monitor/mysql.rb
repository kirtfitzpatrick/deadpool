# Assumes at a minimum the following config:
# --
# primary_host:   '127.0.0.1'
# secondary_host: '127.0.0.1'
# monitor_config:
#   nagios_plugin_path: '/usr/lib/nagios/plugins'

module Deadpool

  module Monitor

    class Mysql < Base

      def primary_ok?
        check_mysql(@config[:primary_host])
      end

      def secondary_ok?
        check_mysql(@config[:secondary_host]) &&
        check_mysql_slave(@config[:secondary_host])
      end

      protected

      def check_mysql(host)
        check_mysql_plugin = File.join nagios_plugins_path, 'check_mysql'
        check_command      = "#{check_mysql_plugin} -H #{host} -u monitor -p 'M0n1t0r'"
        logger.debug check_command
        status_message     = `#{check_command}`
        exit_status        = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status == 0
      end

      def check_mysql_slave(host)
        check_mysql_slave_plugin = File.join nagios_plugins_path, 'check_mysql'
        check_command            = "#{check_mysql_slave_plugin} -H #{host} -u monitor -p 'M0n1t0r' --check-slave"
        logger.debug check_command
        status_message           = `#{check_command}`
        exit_status              = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status
      end

      def nagios_plugins_path
        config[:monitor_config][:nagios_plugin_path]
      end

    end

  end

end
