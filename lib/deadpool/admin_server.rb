
require 'json'

module Deadpool

  module AdminServer

    attr_accessor :deadpool_server

    # data should be a JSON encoded hash.  It must have a command key.
    # {
    #   'command' => 'command', 
    #   'pool'    => 'pool_name', 
    #   'server'  => 'server_label'
    # }
    def receive_data(data)
      if data.to_s =~ /command/        
        deadpool_server.logger.debug "Received instruction: #{data}"
        options = JSON.parse(data.to_s)

        case options['command']
        when 'full_report'
          send_data full_report
        when 'nagios_report'
          send_data nagios_report
        when 'promote_server'
          send_data promote_server options
        when 'stop'
          send_data stop
        else
          send_data "Server did not understand the command."
        end
      end

      close_connection_after_writing
    end

    protected
    
    def full_report
      return deadpool_server.system_check(true).full_report
    end

    def nagios_report
      return deadpool_server.system_check.nagios_report
    end

    def promote_server(options)
      if deadpool_server.promote_server(options['pool'], options['server'].to_sym)
        return "Success.\n"
      else
        return "Failed!\n"
      end
    end

    def stop
      close_connection
      deadpool_server.kill
    end

  end

end


