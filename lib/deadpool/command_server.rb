require 'json'

module Deadpool
  module CommandServer
    attr_accessor :deadpool_server

    # data should be a JSON encoded hash.  It must have a command key.
    # {
    #   'command' => 'command',
    #   'pool'    => 'pool_name',
    #   'server'  => 'server_label'
    # }
    def receive_data(data)
      data = data.to_s

      if data =~ /command/
        deadpool_server.logger.debug "Received instruction: #{data}"
        options = JSON.parse(data)

        case options['command']
        when 'full_report'
          send_data full_report
        when 'nagios_report'
          send_data nagios_report
        when 'promote'
          send_data promote options
        when 'stop'
          send_data stop
        else
          send_data 'Server did not understand the command.'
        end
      end

      close_connection_after_writing
    end

    protected

    def full_report
      deadpool_server.system_check(true).full_report
    end

    def nagios_report
      deadpool_server.system_check.nagios_report
    end

    def promote(options)
      if deadpool_server.promote(options['pool'], options['server'].to_sym)
        "Success.\n"
      else
        "Failed!\n"
      end
    end

    def stop
      close_connection
      deadpool_server.kill
    end
  end
end
