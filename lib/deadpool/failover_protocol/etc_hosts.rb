
require 'net/ssh'

module Deadpool

  module FailoverProtocol

    class EtcHosts < Base

      def setup
        @script_path        = @failover_config[:script_path]
        @service_host_name  = @failover_config[:service_host_name]
        @service_hosts_file = @failover_config[:service_hosts_file]
        @client_hosts       = @failover_config[:client_hosts]
        @username           = @failover_config[:username]
        @password           = @failover_config[:password]
        @use_sudo           = @failover_config[:use_sudo]
        @sudo_path          = @failover_config[:sudo_path].nil? ? 'sudo' : @failover_config[:sudo_path]
      end

      def preflight_check
        @client_hosts.map { |h| test_client(h) && verify_client(h) }.all?
      end

      def test_client(client_host)
        logger.debug "Testing Client #{client_host}"
        output = run_script_command(client_host, '--test')
        logger.debug "Output recieved From Client: #{output}"

        if output.class == String
          okay = (output =~ /^OK/) != nil
          okay ? logger.info("#{client_host}: " + output.strip) : logger.error("#{client_host}: " + output.strip)
        else
          logger.error "Test Client had a critical failure on '#{client_host}'"
        end

        return okay
      end

      def verify_client(client_host, primary_host=nil)
        logger.debug "Verifying Client #{client_host}"
        primary_host      = primary_host.nil? ? @primary_host : primary_host
        command_arguments = "--verify --host_name='#{@service_host_name}' --ip_address='#{primary_host}'"
        command_arguments += " --host_file='#{@service_hosts_file}'" if @service_hosts_file
        output            = run_script_command(client_host, command_arguments)
        logger.debug "Output recieved From Client: #{output}"

        if output.class == String
          okay = (output =~ /^OK/) != nil
          okay ? logger.info("#{client_host}: " + output.strip) : logger.error("#{client_host}: " + output.strip)
        else
          logger.error "Verify Client had a critical failure on '#{client_host}'"
        end

        return okay
      end

      def promote_to_primary(new_primary)
        @client_hosts.map do |client_host|
          # logger.debug "client_host: #{client_host}, New Primary: #{new_primary}"
          promote_to_primary_on_client(client_host, new_primary)
        end.all?
      end

      def promote_to_primary_on_client(client_host, new_primary)
        # logger.debug "Assigning #{new_primary} as new primary on #{client_host}"
        command_arguments = "--switch --host_name='#{@service_host_name}' --ip_address='#{new_primary}'"
        command_arguments += " --host_file='#{@service_hosts_file}'" if @service_hosts_file
        output            = run_script_command(client_host, command_arguments)
        logger.debug "Output received From Client: #{output}"

        if output.class == String
          okay = (output =~ /^OK/) != nil
          okay ? logger.info("#{client_host}: " + output.strip) : logger.error("#{client_host}: " + output.strip)
        else
          logger.error "Promote to Primary on Client had a critical failure on '#{client_host}'"
        end

        return okay
      end
  
      def system_check
        writable             = []
        not_writable         = []
        pointed_at_primary   = []
        pointed_at_secondary = []
        pointed_at_neither   = []
    
        # Collect check data
        @client_hosts.each do |client_host|
          if test_client(client_host)
            writable << client_host
          else
            not_writable << client_host
          end

          if verify_client(client_host, @primary_host)
            pointed_at_primary << client_host
          else
            if verify_client(client_host, @secondary_host)
              pointed_at_secondary << client_host
            else
              pointed_at_neither << client_host
            end
          end
        end
    
        # Compile write check data.
        if !writable.empty? && not_writable.empty?
          @state.set_state OK, "Write check passed all servers: #{writable.join(', ')}"
        elsif !writable.empty? && !not_writable.empty?
          @state.set_state WARNING, "Write check passed on: #{writable.join(', ')}"
          @state.add_error_message "Write check failed on #{not_writable.join(', ')}"
        elsif writable.empty?
          @state.set_state WARNING, "Write check failed all servers: #{not_writable.join(', ')}"
        end
    

        # Compile verification data
        if !pointed_at_primary.empty? && pointed_at_secondary.empty? && pointed_at_neither.empty?
          @state.add_message "All client hosts are pointed at the primary."
        elsif pointed_at_primary.empty? && !pointed_at_secondary.empty? && pointed_at_neither.empty?
          @state.escalate_status_code WARNING
          @state.add_error_message "All client hosts are pointed at the secondary."
        else
          @state.escalate_status_code CRITICAL
          @state.add_error_message "Client hosts are pointing in different directions."
        end

        return Deadpool::StateSnapshot.new @state
      end


      protected

      def run_script_command(host, command_arguments)
        options = @password.nil? ? {} : {:password => @password}
        command = "#{@script_path} #{command_arguments}"
        command = "#{@sudo_path} #{command}" if @use_sudo

        logger.debug "executing #{command} on #{host}"

        begin
          Net::SSH.start(host, @username, options) do |ssh|
            return ssh.exec!(command)
          end
        rescue
          logger.error "Couldn't execute #{command} on #{host}"
          return false
        end
      end

    end
    
  end

end
