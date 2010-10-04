
module Deadpool

  module FailoverProtocol

    class ExecRemoteCommand < Base

      def setup
        @test_command = @failover_config[:test_command]
        @exec_command = @failover_config[:exec_command]
        @client_hosts = @failover_config[:client_hosts]
        @username     = @failover_config[:username]
        @password     = @failover_config[:password]
        @use_sudo     = @failover_config[:use_sudo]
        @sudo_path    = @failover_config[:sudo_path].nil? ? 'sudo' : @failover_config[:sudo_path]
      end

      # Return true or false
      # Don't update system state.
      # return true or false success or failure
      def preflight_check
        @client_hosts.all? { |client_host| test_client(client_host) }
      end

      def test_client(client_host)
        logger.debug "Testing Client #{client_host}"
        return exec_remote_command(@test_command, client_host)
      end

      # Promote the host to primary.  This is used by initiate_failover_protocol!
      # and for manual promotion by an administrator.
      # new_primary is an IP address
      # TODO: change new_primary to be a config label.
      # return true or false success or failure
      def promote_to_primary(new_primary)
        success = true

        @client_hosts.each do |client_host|
          if exec_remote_command(@exec_command, client_host)
            exec_remote_command(@exec_command, client_host)
            logger.info "Promotion exec command succeeded on #{client_host}"
          else
            logger.error "Promotion exec command failed on #{client_host}"
          end
        end

        return success
      end

      # Perform checks against anything that could cause a failover protocol to fail
      # Perform checks on system state.
      # return New Deadpool::StateSnapshot
      def system_check
        failed    = []
        succeeded = []

        # Collect check data
        @client_hosts.each do |client_host|
          if test_client(client_host)
            failed << client_host
          else
            succeeded << client_host
          end
        end

        # Compile write check data.
        if !succeeded.empty? && failed.empty?
          @state.set_state OK, "Exec test passed all servers: #{succeeded.join(', ')}"
        elsif !succeeded.empty? && !failed.empty?
          @state.set_state WARNING, "Exec test passed on: #{succeeded.join(', ')}"
          @state.add_error_message "Exec test failed on #{failed.join(', ')}"
        elsif succeeded.empty?
          @state.set_state WARNING, "Exec test failed all servers: #{failed.join(', ')}"
        end

        return Deadpool::StateSnapshot.new @state
      end

      protected

      def exec_remote_command(command, host)
        options = @password.nil? ? {} : {:password => @password}
        command = "#{command} && echo 'ExecRemoteCommand.success: '$?"
        command = "#{@sudo_path} #{command}" if @use_sudo

        logger.debug "executing #{command} on #{host}"

        begin
          Net::SSH.start(host, @username, options) do |ssh|
            output = ssh.exec!(command)
          end

          return output =~ /ExecRemoteCommand.success: 0/
        rescue
          logger.error "Couldn't execute #{command} on #{host}"
          return false
        end
      end

    end

  end

end
