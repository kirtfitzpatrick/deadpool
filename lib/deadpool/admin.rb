
require 'optparse'
require 'ostruct'
require 'strscan'
require 'socket'
require 'json'


module Deadpool

  class Admin

    def initialize(argv)
      @argv     = argv
    end

    def run
      @options = self.parse_command_line
      @config  = Deadpool::Helper.configure @options

      self.execute_command(@options)
    end

    def parse_command_line
      options               = Hash.new
      options[:command_count] = 0
      options[:config_path]     = '/etc/deadpool'

      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: deadpool-hosts --command [options]"

        opts.separator "Commands:"
        opts.on("-h", "--help", "Print this help message.") do |help|
          options[:command_count] += 1
          options[:command]        = :help
        end
        opts.on("--full_report", "Give the full system report.") do |full_report|
          options[:command_count] += 1
          options[:command]        = :full_report
        end
        opts.on("--nagios_report", "Report system state in Nagios plugin format.") do |nagios_report|
          options[:command_count] += 1
          options[:command]        = :nagios_report
        end
        opts.on("--promote_server", "Promote specified server to the master.") do |nagios_report|
          options[:command_count] += 1
          options[:command]        = :promote_server
        end
        opts.on("--stop", "Stop the server.") do |stop|
          options[:command_count] += 1
          options[:command]        = :stop
        end
        opts.on("--start", "Start the server in the background.") do |stop|
          options[:command_count] += 1
          options[:command]        = :start
        end
        opts.on("--foreground", "Start the server in the foreground.") do |stop|
          options[:command_count] += 1
          options[:command]        = :foreground
        end

        opts.separator "Options:"
        opts.on("--server=SERVER_LABEL", String, "primary_host or secondary_host.") do |server|
          options[:server] = server
        end
        opts.on("--pool=POOL_NAME", String, "Deadpool name to operate on.") do |pool|
          options[:pool] = pool
        end
        opts.on("--config_path=PATH", String, 
            "Path to configs and custom plugins. #{options[:config_path]} by default.") do |config_path|
          options[:config_path] = config_path
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
      when :help
        help
      when :full_report
        full_report options
      when :nagios_report
        nagios_report options
      when :promote_server
        promote_server options
      when :stop
        stop options
      when :start
        start options
      when :foreground
        foreground options
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

    def full_report(options)
      puts send_command_to_deadpool_server :command => 'full_report'
    end

    def nagios_report(options)
      response = send_command_to_deadpool_server :command => 'nagios_report'

      if (response.to_s =~ /^OK/) != nil
        puts response.to_s
        exit OK
      elsif (response.to_s =~ /^WARNING/) != nil
        puts response.to_s
        exit WARNING
      elsif (response.to_s =~ /^CRITICAL/) != nil
        puts response.to_s
        exit CRITICAL
      elsif (response.to_s =~ /^UNKNOWN/) != nil
        puts response.to_s
        exit UNKNOWN
      else
        puts "UNKNOWN - #{response.to_s}"
        exit UNKNOWN
      end
    end

    def promote_server(options)
      error_messages = []

      if options[:pool].nil?
        error_messages << "Promoting server requires --pool argument."
      end

      if options[:server].nil?
        error_messages << "Promoting server requires --server argument."
      end
      
      unless error_messages.empty?
        help error_messages.join "\n"
      end

      puts send_command_to_deadpool_server :command => 'promote_server', :pool => options[:pool], :server => options[:server]
    end

    def stop(options)
      puts send_command_to_deadpool_server :command => 'stop'
    end

    def start(options)
      puts Deadpool::Server.new(options).run(true)
    end

    def foreground(options)
      puts Deadpool::Server.new(options).run(false)
    end

    def send_command_to_deadpool_server(options)
      output = ''

      begin
        socket = TCPSocket.open(@config[:admin_hostname], @config[:admin_port])
      rescue
        return "Couldn't connect to deadpool server.  Is it running?"
      end

      if socket
        socket.puts JSON.dump(options)
        while line = socket.gets
          output += line
        end
        socket.close
      else
        return "Couldn't connect to deadpool server."
      end

      return output
    end

  end

end

