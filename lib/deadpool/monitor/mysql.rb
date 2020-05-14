# Assumes at a minimum the following config:
# --
# primary_host:   '127.0.0.1'
# secondary_host: '127.0.0.1'
# monitor_config:
#   nagios_plugin_path: '/usr/lib/nagios/plugins/check_mysql'
require 'timeout'

module Deadpool

  module Monitor

    class Mysql < Base

      def primary_ok?
        return check_mysql(@config[:primary_host])
      end

      def secondary_ok?
        return check_mysql(@config[:secondary_host]) 
        # && check_mysql_slave(@config[:secondary_host])
      end

      protected

      def check_mysql(host)
        check_command      = "#{nagios_plugin_path} -H #{host} -u '#{username}' -p '#{password}'"
        logger.debug check_command
        exit_status, status_message = check_with_timeout(check_command)
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status == 0
      end

      def check_mysql_slave(host)
        check_command  = "#{nagios_plugin_path} -H #{host} -u '#{username}' -p '#{password}' --check-slave"
        logger.debug check_command
        exit_status, status_message = check_with_timeout(check_command)
        logger.debug "MySQL Check Status Message: #{status_message}"
        logger.debug "MySQL Check Exit Status: #{exit_status}"

        return exit_status == 0
      end

      def check_with_timeout(shell_command)
        r, w = IO.pipe
        pid = Process.spawn(shell_command, :err=>:out, :out=>w)

        begin
          Timeout.timeout(5) do
            pid, status = Process.wait2(pid)
            w.close

            return status.exitstatus, r.read
          end
        rescue Timeout::Error
          Process.kill('TERM', pid)
          w.close

          return 1, "Check Timed Out: #{shell_command}"
        end
      end

      def nagios_plugin_path
        @config[:monitor_config][:nagios_plugin_path]
      end

      def username
        @config[:monitor_config][:username]
      end

      def password
        @config[:monitor_config][:password]
      end
    end

  end

end
