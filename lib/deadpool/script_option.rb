module Deadpool
  class ScriptOption

    attr :value,
         :default,
         :name

    def initialize(name, default)
      @name = name
      @default = @value = default
    end

    def parse_script_args(script_args)
      arg_val = script_args[cli_key]
      @value = arg_val if arg_val.is_a?(String)
    end

    def cli_key
      dashed_name.to_sym
    end

    def cli_flag
      "--#{dashed_name}"
    end

    def to_sym
      name.to_sym
    end

    protected

    def dashed_name
      name.downcase.gsub('_', '-')
    end
  end
end
