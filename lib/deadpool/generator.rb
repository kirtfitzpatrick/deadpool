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
      deadpool-admin_path = `which deadpool-admin`.strip
      
      upstart_conf =<<-EOF
description     "Deadpool Service"
author          "Kirt Fitzpatrick <kirt.fitzpatrick@akqa.com>"

umask 007
start on (net-device-up and local-filesystems)
stop on runlevel [016]
respawn
exec #{ruby_path} #{deadpool-admin_path} --foreground #{config_params}

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
            # puts ls_command
            # puts `#{ls_command}`
            # puts "ln -s #{upstart_script_path} #{upstart_init_path}"
          else
            `ln -s #{upstart_script_path} #{upstart_init_path}`
          end
        end
      else
        puts upstart_conf
      end
    end

    # mkdir path/config/pools
    #       path/config/environment.yml
    #       path/config/pools/example.yml
    # mkdir path/lib/deadpool/monitor
    #       path/lib/deadpool/monitor
    # mkdir path/lib/deadpool/failover_protocol
    #       path/lib/deadpool/failover_protocol
    def generate_configuration(options)
      path = options[:config_path]
      FileUtils.mkdir_p(File.join(path, 'config/pools'))
      FileUtils.mkdir_p(File.join(path, 'lib/deadpool/monitor'))
      FileUtils.mkdir_p(File.join(path, 'lib/deadpool/failover_protocol'))
      File.open File.join(path, 'config/pools/example.yml'), 'w' do |file|
        file.write <<-EOF
pool_name:         'example_database'
primary_host:      '10.1.2.3'
secondary_host:    '10.2.3.4'
check_interval:    1
max_failed_checks: 10

# There can be only one monitor per pool at this time.  The deadpool system
# defines no rules for the monitor configuration except that it is called
# monitor_config: and has monitor_class: defined at the base level.  
# All other configuration variables are plugin specific.
monitor_config:
  monitor_class: Mysql
  nagios_plugin_path: '/usr/lib/nagios/plugins'

# There can be as many Failover Protocols as you want and you can use 
# the same plugin multiple times.  The deadpool defines no riles for the 
# failover protocol config except that it be an array element of 
# failover_protocol_configs and defines protocol_class at it's base.  The rest
# of the configuration is specific to the failover protocol.
failover_protocol_configs:
  - protocol_class: EtcHosts
    script_path: '/usr/local/bin/deadpool_line_modifier'
    service_host_name: 'master.mysql.example.project.client'
    username: 'deadpool'
    password: 'p4ssw0rd'
    use_sudo: 1
    client_hosts:
      - '10.3.4.5'   # app server 1 (web server)
      - '10.4.5.6'   # app server 2 (web server)

  - protocol_class: ExecRemoteCommand
    test_command: '/etc/init.d/nginx status'
    exec_command: '/etc/init.d/nginx restart'
    username: 'deadpool'
    password: 'p4ssw0rd'
    use_sudo: 1
    client_hosts:
      - '10.3.4.5'   # app server 1 (web server)
      - '10.4.5.6'   # app server 2 (web server)
        EOF
      end
      
      environment_config_path = File.join(path, 'config/environment.yml')
      environment_conf = <<-EOF
log_path: '/var/log/deadpool.log'
log_level: INFO
system_check_interval: 30
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
