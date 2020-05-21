require 'optparse'
require 'strscan'
require 'fileutils'

module Deadpool
  module Generator
    class UpstartConfig

      attr :active

      alias active? active

      def initialize
        @active = false
        @options = [
          Deadpool::ScriptOption.new('deadpool_config_dir', '/etc/deadpool'),
          Deadpool::ScriptOption.new('upstart_config', '/etc/init/deadpool.conf'),
          Deadpool::ScriptOption.new('upstart_init', '/etc/init.d/deadpool'),
          Deadpool::ScriptOption.new('upstart_script', '/lib/init/upstart-job')
        ]
        define_option_methods
      end

      def generate(script_args)
        parse_script_args(script_args)
        generate_upstart_conf
        create_upstart_link
      end

      # :reek:FeatureEnvy
      def add_options_to_parser(parser)
        parser.separator 'Upstart:'
        parser.on('-u', '--upstart', 'Configure deadpool upstart service.') do
          @active = true
        end
        @options.each do |option|
          parser.on("#{option.cli_flag} PATH", String, 
                    "Default: #{option.default}")
        end
      end

      protected

      def define_option_methods
        @options.each do |option|
          define_singleton_method(option.name.to_sym) do
            option.value
          end
        end
      end

      def parse_script_args(script_args)
        @options.each { |option| option.parse_script_args(script_args) }
      end

      def generate_upstart_conf
        config_dir_flag = "--deadpool-config-dir=#{deadpool_config_dir}"
        ruby_path = `which ruby`.strip
        deadpool_path = `which deadpool`.strip

        File.open upstart_config, 'w' do |file|
          file.write <<~UPSTART_CONF
            description     "Deadpool Service"
            author          "Kirt Fitzpatrick"
            
            umask 007
            start on (net-device-up and local-filesystems)
            stop on runlevel [016]
            respawn
            exec #{ruby_path} #{deadpool_path} --foreground #{config_dir_flag}
            
          UPSTART_CONF
        end
        puts "Created #{upstart_config}"
      end

      def create_upstart_link
        unless File.exist? upstart_script
          puts "The upstart script is not at #{upstart_script}."
          exit 4
        end

        if File.exist? upstart_init
          puts "#{upstart_init} already exists. "\
               "It should be a symbolic link that points to #{upstart_script}"
          exit 4
        end

        `ln -s #{upstart_script} #{upstart_init}`
        puts "Created link from #{upstart_init} to #{upstart_script}"
      end
    end
  end
end