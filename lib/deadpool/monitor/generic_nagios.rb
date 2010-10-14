# Assumes at a minimum the following config:
# --
# primary_host:   '127.0.0.1'
# secondary_host: '127.0.0.1'
# monitor_config:
#   nagios_plugin_path: '/usr/lib/nagios/plugins/check_something'

module Deadpool

  module Monitor

    class GenericNagios < Base

      def primary_ok?
        check_host(@config[:primary_host])
      end

      def secondary_ok?
        check_host(@config[:secondary_host])
      end

      protected

      def check_host(host)
        check_command  = "#{nagios_plugin_path} -H #{host} #{nagios_options}"
        logger.debug check_command
        status_message = `#{check_command}`
        exit_status    = $?
        logger.debug "Generic Nagios Check Status Message: #{status_message}"
        logger.debug "Generic Nagios Check Exit Status: #{exit_status}"

        return exit_status == 0
      end

      def nagios_plugin_path
        @config[:monitor_config][:nagios_plugin_path]
      end

      def nagios_options
        @config[:monitor_config][:nagios_options]
      end

    end

  end

end
