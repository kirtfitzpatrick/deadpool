
module Deadpool

  class Helper

    def self.symbolize_keys(arg)
      case arg
      when Array
        arg.map { |elem| symbolize_keys elem }
      when Hash
        Hash[
          arg.map { |key, value|  
            k = key.is_a?(String) ? key.to_sym : key
            v = symbolize_keys value
            [k,v]
          }]
      else
        arg
      end
    end

    def self.configure(options)
      default_config = YAML.load(File.read(File.join(File.dirname(__FILE__), '../../config/default_environment.yml')))

      begin
        user_config = YAML.load(File.read(File.join(options[:config_path], 'environment.yml')))
      rescue
        user_config = Hash.new
      end

      return Deadpool::Helper.symbolize_keys default_config.merge(user_config).merge(options)
    end

    def self.setup_logger(config, foreground=false)
      stream = foreground ? STDOUT : config[:log_path]
      logger = Logger.new(stream)
      logger.level = Logger.const_get(config[:log_level].upcase)
      
      return logger
    end

  end

end
