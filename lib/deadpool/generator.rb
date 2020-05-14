require 'optparse'
require 'ostruct'
require 'strscan'
require 'fileutils'

module Deadpool
  class Generator

    # include FileUtils

    def initialize(argv)
      @argv     = argv
    end

    def run
      @options = self.parse_command_line
      @config  = Deadpool::Helper.configure @options

      self.execute_command(@options)
    end

    def parse_command_line
      options                       = Hash.new
      options[:command_count]       = 0
      options[:config_path]         = '/etc/deadpool'
      options[:upstart_config_path] = '/etc/init/deadpool.conf'
      options[:upstart_init_path]   = '/etc/init.d/deadpool'
      options[:upstart_script_path] = '/lib/init/upstart-job'

      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: deadpool-generator command [options]"

        opts.separator "Commands:"
        opts.on("-h", "--help", "Print this help message.") do |help|
          options[:command_count] += 1
          options[:command]        = :help
        end
        opts.on("-u", "--upstart_init", "Generate and upstart config.") do |upstart|
          options[:command_count] += 1
          options[:command]        = :upstart_init
        end
        opts.on("-c", "--configuration", "Generate a config directory structure and example files.") do |configuration|
          options[:command_count] += 1
          options[:command]        = :configuration
        end
      
        opts.separator "Configuration Options:"
        opts.on("--config_path=PATH", String, "path to create the config dir at (#{options[:config_path]})") do |config_path|
          options[:config_path] = config_path
        end

        opts.separator "Upstart Options:"
        opts.on("--upstart_config_path=PATH", String, "path to create the config dir at (#{options[:upstart_config_path]})") do |upstart_config_path|
          options[:upstart_config_path] = upstart_config_path
        end
        opts.on("--upstart_init_path=PATH", String, "path to create the config dir at (#{options[:upstart_init_path]})") do |upstart_init_path|
          options[:upstart_init_path] = upstart_init_path
        end
        opts.on("--upstart_script_path=PATH", String, "path to create the config dir at (#{options[:upstart_script_path]})") do |upstart_script_path|
          options[:upstart_script_path] = upstart_script_path
          unless File.exists? upstart_script_path
            help "The upstart script is not at #{upstart_script_path}."
          end
        end
      end

        remaining_arguments = @option_parser.parse! @argv

        unless remaining_arguments.empty?
          help "[#{remaining_arguments.join(' ')}] is not understood."
        end

        if options[:command_count] == 0
          help "You must specify a command."
        end

        return options
      end

      def execute_command(options)
        case options[:command]
        when :upstart_init
          generate_upstart_init options
        when :configuration
          generate_configuration options
        else
          help
        end
      end

    def help(message=nil)
      unless message.nil?
        puts message
      end
      puts @option_parser.help
      exit 4
    end

    def generate_upstart_init(options)
      config_path         = options[:config_path]
      upstart_config_path = options[:upstart_config_path]
      upstart_init_path   = options[:upstart_init_path]
      upstart_script_path = options[:upstart_script_path]
      config_params       = config_path.nil? ? '' : "--config_path=#{config_path}"
      ruby_path           = `which ruby`.strip
      deadpool_admin_path = `which deadpool-admin`.strip
      
      upstart_conf =<<-EOF
description     "Deadpool Service"
author          "Kirt Fitzpatrick"

umask 007
start on (net-device-up and local-filesystems)
stop on runlevel [016]
respawn
exec #{ruby_path} #{deadpool_admin_path} --foreground #{config_params}

      EOF

      if upstart_config_path
        File.open File.join(upstart_config_path), 'w' do |file|
          file.write upstart_conf
        end
        
        if upstart_init_path 
          if File.exists? upstart_init_path
            puts "#{upstart_config_path} has been (over)written."
            puts "#{upstart_init_path} already exists.  It should be a symbolic link that points to #{upstart_script_path}"
            ls_command = "ls -l #{upstart_init_path}"
          else
            `ln -s #{upstart_script_path} #{upstart_init_path}`
          end
        end
      else
        puts upstart_conf
      end
    end

    # mkdir path/pools
    #       path/environment.yml
    #       path/pools/example.yml
    def generate_configuration(options)
      path = options[:config_path]
      FileUtils.mkdir_p(File.join(path, 'pools'))
      File.open File.join(path, 'pools/example.yml'), 'w' do |file|
        file.write <<-EOF
pool_name:         'example_mysql'
primary_host:      '10.1.2.3'
secondary_host:    '10.2.3.4'
check_interval:    1    # in seconds
max_failed_checks: 10   # How many failed checks to allow before performing a failover

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

        EOF
      end
      
      environment_config_path = File.join(path, 'environment.yml')
      environment_conf = <<-EOF
log_path: '/var/log/deadpool.log'
log_level: INFO             # Alternatively DEBUG, WARN, ERROR
# The system check verifys everything including the failover protocols.
# i.e. Can deadpool ssh into the clients? Can deadpool write to /etc/hosts on each client? etc.
system_check_interval: 30
# How the deadpool-admin cli communicates with the deadpool service.
# If this port or hostname doesn't work for you, change it.
admin_hostname: 'localhost'
admin_port: 5507

      EOF
      if File.exists? environment_config_path
        puts "#{environment_config_path} already exists.  Here's what we would have copied there."
        puts environment_conf
      else
        File.open environment_config_path, 'w' do |file|
          file.write environment_conf
        end
      end
      
      puts "Configuration saved to #{path}"
    end

  end

end
