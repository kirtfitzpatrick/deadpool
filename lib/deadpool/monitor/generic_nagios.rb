# Assumes at a minimum the following config:
# --
# primary:   '127.0.0.1'
# secondary: '127.0.0.1'
# monitor_config:
#   nagios_plugin_path: '/usr/lib/nagios/plugins/check_something'

module Deadpool
  module Monitor
    class GenericNagios < Base

      def primary_ok?
        check_host(@config[:primary])
      end

      def secondary_ok?
        check_host(@config[:secondary])
      end

      protected

      def check_host(host)
        check_command = "#{nagios_plugin_path} #{nagios_options} -H #{host}"
        logger.debug check_command
        status_message = `#{check_command}`
        exit_status = $?
        logger.debug "Generic Nagios Check Status Message: #{status_message}"
        logger.debug "Generic Nagios Check Exit Status: #{exit_status}"

        exit_status == 0
      end

      def nagios_plugin_path
        @monitor_config[:nagios_plugin_path]
      end

      def nagios_options
        @monitor_config[:nagios_options]
      end

    end
  end
end
