# frozen_string_literal: true

module Deadpool
  class State

    attr_reader :name, :timestamp, :status_code, :error_messages, :all_messages

    def initialize(name, klass = nil)
      names = []
      names << name unless name.nil? || name.empty?
      names << klass.to_s unless klass.nil?
      @name = names.join ' - '
      @locked = false
      reset!
    end

    def lock
      @locked = true
    end

    def unlock
      @locked = false
    end

    def set_state(code, message)
      unless @locked
        if code == OK
          @timestamp = Time.now
          @status_code = OK
          @error_messages = []
          @all_messages = [message]
        else
          @timestamp = Time.now
          @status_code = code
          @error_messages = [message]
          @all_messages = []
        end
      end
    end

    def reset!(message = nil)
      unless @locked
        @timestamp = Time.now
        @status_code = OK
        @error_messages = []
        @all_messages = message.nil? ? [] : [message]
      end
    end

    def escalate_status_code(code)
      unless @locked
        @timestamp = Time.now

        @status_code = code if code >= @status_code
      end
    end

    def add_message(message)
      unless @locked
        @timestamp = Time.now
        @all_messages << message
      end
    end

    def add_error_message(message)
      unless @locked
        @timestamp = Time.now
        @error_messages << message
        # @all_messages << message
      end
    end

  end
end
