# Assumes at a minimum the following config:
# --
# primary_host:   '127.0.0.1'
# secondary_host: '127.0.0.1'
# monitor_config:
#   nagios_plugin_path: '/usr/lib/nagios/plugins/check_mysql'

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
        check_command      = "#{nagios_plugin_path} -H #{host} -u '#{username}' -p '#{password}'"
        logger.debug check_command
        status_message     = `#{check_command}`
        exit_status        = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status == 0
      end

      def check_mysql_slave(host)
        check_command  = "#{nagios_plugin_path} -H #{host} -u '#{username}' -p '#{password}' --check-slave"
        logger.debug check_command
        status_message = `#{check_command}`
        exit_status    = $?
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status
      end

      def nagios_plugin_path
        @config[:monitor_config][:nagios_plugin_path]
      end

      def username
        @config[:monitor_config][:username]
      end

      def username
        @config[:monitor_config][:password]
      end
    end

  end

end
