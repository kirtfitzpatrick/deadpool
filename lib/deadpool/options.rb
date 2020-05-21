require 'optparse'
require 'ostruct'
require 'strscan'

module Deadpool
  module Options
    def parse_options(argv)
      @options = parse_command_line(argv)
    end

    def parse_command_line(argv)
      options = {}
      options[:config_path] = '/etc/deadpool'
      options[:daemonize] = nil

      @option_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: deadpool-hosts {help|full_report|nagios_report} [options]'

        opts.separator 'Commands:'
        opts.on('-h', '--help', 'Print this help message.') do |_help|
          options[:help] = true
        end

        opts.on('-d', '--daemon', 'Background the server.') do |_daemon|
          options[:daemonize] = true
        end

        opts.separator 'Options:'
        opts.on('--config_path=PATH', String,
                "Path to configs and custom plugins. #{options[:config_path]} by default.") do |config_path|
          options[:config_path] = config_path
        end
      end

      remaining_arguments = @option_parser.parse! argv

      unless remaining_arguments.empty?
        help "[#{remaining_arguments.join(' ')}] is not understood."
      end

      options
    end

    def help(message = nil)
      puts message unless message.nil?
      puts @option_parser.help
      exit 4
    end

    def config_path
      @options[:config_path]
    end
  end
end
