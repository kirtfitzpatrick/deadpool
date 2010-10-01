
require 'optparse'
require 'ostruct'
require 'strscan'


module Deadpool

  module Options

    def parse_options(argv)
      @options = self.parse_command_line(argv)
    end

    def parse_command_line(argv)
      options             = {}
      options[:configdir] = '/etc/deadpool'
      options[:daemonize] = nil

      @option_parser = OptionParser.new do |opts|
        opts.banner = "Usage: etc_hosts_switch {help|full_report|nagios_report} [options]"

        opts.separator "Commands:"
        opts.on("-h", "--help", "Print this help message.") do |help|
          options[:help] = true
        end

        opts.on("-d", "--daemon", "Background the server.") do |daemon|
          options[:daemonize] = true
        end

        opts.separator "Options:"
        opts.on("--configdir=PATH", String,
            "Path to configs and custom plugins. #{options[:configdir]} by default.") do |configdir|
          options[:configdir] = configdir
        end
      end

      remaining_arguments = @option_parser.parse! argv

      unless remaining_arguments.empty?
        help "[#{remaining_arguments.join(' ')}] is not understood."
      end

      return options
    end

    def help(message=nil)
      unless message.nil?
        puts message
      end
      puts @option_parser.help
      exit 4
    end

    def configdir
      return @options[:configdir]
    end

  end

end
