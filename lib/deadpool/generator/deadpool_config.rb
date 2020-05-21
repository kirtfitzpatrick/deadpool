require 'optparse'
require 'strscan'
require 'fileutils'

module Deadpool
  module Generator
    class DeadpoolConfig

      attr :active

      alias active? active

      def initialize
        @active = false
        @config_dir = Deadpool::ScriptOption.new('deadpool_config', '/etc/deadpool')
      end

      # :reek:FeatureEnvy
      def add_options_to_parser(parser)
        parser.separator 'Deadpool:'
        parser.on('-d', '--deadpool-config [PATH]',
                  'Config directories and example files. '\
                  "Default: #{@config_dir.default}") do
          @active = true
        end
      end

      def generate(script_args)
        @config_dir.parse_script_args(script_args)
        make_directories
        generate_system_conf
        generate_pool
        puts "Configuration saved to #{config_dir}"
      end

      protected

      def config_dir
        @config_dir.value
      end

      def make_directories
        FileUtils.mkdir_p(File.join(config_dir, 'pools'))
      end

      def generate_system_conf
        system_conf_filename = File.join(config_dir, 'system.yml')
        system_conf = <<~SYSTEM_CONF
          log_path: '/var/log/deadpool.log'
          log_level: INFO                   # Alternatively DEBUG, WARN, ERROR
          system_check_interval: 30
          admin_hostname: 'localhost'
          admin_port: 5507
          
        SYSTEM_CONF

        if File.exist? system_conf_filename
          puts "#{system_conf_filename} already exists. "\
               "Here's what we would have copied there."
          puts system_conf
        else
          File.open system_conf_filename, 'w' do |file|
            file.write system_conf
          end
        end
      end

      def generate_pool
        pool_filename = File.join(config_dir, 'pools/example.yml')
        File.open pool_filename, 'w' do |file|
          file.write <<~POOL_CONF
            pool_name:         'example_mysql'
            primary:           '10.1.2.3'
            secondary:         '10.2.3.4'
            check_interval:    1    # in seconds
            max_failed_checks: 10   # No. failed checks before performing failover
            
            monitor_config:
              # Mysql, GenericNagios, or Redis
              monitor_class: Mysql
              # Full path to plugin
              nagios_plugin_path: '/usr/lib/nagios/plugins/check_mysql'
            
            failover_protocol_configs:
              # EtcHost is a built-in just for handling /etc/hosts manipulation
              - protocol_class: EtcHosts
                script_path: '/usr/local/bin/deadpool-hosts'
                # service_host_name is the name that deadpool will manage in /etc/hosts 
                # it can be anything you like. eg. db.prod.mycompany.org
                service_host_name: 'org.env.service'
                # The user account to connect to all the clients with to monitor and
                # manage their /etc/hosts file with.
                username: 'deadpool'
                password: 'p4ssw0rd'
                use_sudo: 0
                # These are the clients whose /etc/hosts will be monitored and modified
                # by the deadpool server. eg, app servers, job servers, etc.
                client_hosts:
                  - '10.3.4.5'   # app server 1 (web server)
                  - '10.4.5.6'   # app server 2 (web server)
            
              # ExecRemoteCommand is a generic protocol for executing shell commands
              # on the clients.
              - protocol_class: ExecRemoteCommand
                test_command: '/etc/init.d/nginx status'
                exec_command: '/etc/init.d/nginx restart'
                username: 'deadpool'
                password: 'p4ssw0rd'
                # It's recommended to limit the deadpool user to only the sudo
                # commands that you specifically want it to be able to execute
                # by modifying sudoers on the clients
                use_sudo: 1
                client_hosts:
                  - '10.3.4.5'
                  - '10.4.5.6'
            
          POOL_CONF
        end
      end
    end
  end
end
