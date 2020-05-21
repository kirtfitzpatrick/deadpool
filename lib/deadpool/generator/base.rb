require 'optparse'

module Deadpool
  module Generator
    class Base

      def initialize
        @parser = OptionParser.new
        @generators = [
          DeadpoolConfig.new,
          UpstartConfig.new
        ]
        define_cli
      end

      def run(argv)
        script_args = {}
        @parser.parse(argv, into: script_args)
        generators.each do |gen|
          gen.generate script_args if gen.active?
        end
      end

      protected

      attr :generators,
           :parser

      # :reek:TooManyStatements
      def define_cli
        parser.banner = 'Usage: deadpool-gen command [options]'
        parser.on('-h', '--help', 'Print this help message.') do
          puts parser
          exit
        end
        generators.each do |gen|
          gen.add_options_to_parser(@parser)
        end
      end
    end
  end
end
