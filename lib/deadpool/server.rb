

module Deadpool

  class Server

    include Deadpool::Options
    include Deadpool::Daemonizer

    attr_accessor :logger
    attr_reader :config

    def initialize(argv)
      @options = parse_options(argv)
      @state   = Deadpool::State.new 'Deadpool::Server'
      @config  = Deadpool::Helper.configure(@options)
      @logger  = Deadpool::Helper.setup_logger(@config)

      if @options[:daemonize]
        options = @options[:pid_file].nil? ? {} : {:pid => @options[:pid_file]}
        self.daemonize options
      end

      load_handlers
      start_deadpool_handlers
      start_command_server
      schedule_system_check
    end

    def load_handlers
      @handlers = {}
      @state.set_state(OK, 'Loading Handlers.')

      Dir[@options[:configdir] + '/config/pools/*.yml'].each do |pool_yml|
        pool_config = Deadpool::Helper.symbolize_keys YAML.load(File.read(pool_yml))
        @handlers[pool_config[:pool_name]] = Deadpool::Handler.new(pool_config, logger)
      end

      @state.set_state(OK, 'Handlers loaded.')
    end

    def start_deadpool_handlers
      @handlers.each_value do |handler|
        timer = EventMachine::PeriodicTimer.new(handler.check_interval) do
          handler.monitor_pool(timer)
        end
      end
    end

    def schedule_system_check
      timer = EventMachine::PeriodicTimer.new(@config[:system_check_interval]) do
        system_check(true)
      end
    end

    def start_command_server
      EventMachine::start_server @config[:admin_hostname], @config[:admin_port], Deadpool::AdminServer do |connection|
        connection.deadpool_server = self
      end
    end

    def system_check(force=false)
      if force || @cached_state_snapshot.nil?
        @state.reset!
        @cached_state_snapshot = Deadpool::StateSnapshot.new @state

        @handlers.each_value do |handler|
          @cached_state_snapshot.add_child handler.system_check
        end
      end

      return @cached_state_snapshot
    end

    def promote_server(pool_name, server)
      unless @handlers[pool_name].nil?
        # logger.debug "Pool Name: #{pool_name}, Server: #{server}"
        return @handlers[pool_name].promote_server server
      else
        logger.error "'#{pool_name}' pool not found."
        return false
      end
    end

  end

end
