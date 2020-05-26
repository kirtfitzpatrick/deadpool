# frozen_string_literal: true

module Deadpool
  class StateSnapshot

    def initialize(state)
      @name = state.name
      @timestamp = state.timestamp
      @status_code = state.status_code
      @all_messages = state.all_messages
      @error_messages = state.error_messages
      @children = []
    end

    def add_child(child)
      @children << child
    end

    def overall_status
      @children.map(&:overall_status).push(@status_code).max
    end

    def all_error_messages
      @children.inject(@error_messages) do |arr, child|
        arr + child.all_error_messages
      end
    end

    def nagios_report
      message = ''
      message += all_error_messages.join(' | ') if overall_status != OK

      message += " last checked #{(Time.now - @timestamp).round} seconds ago."

      "#{status_code_to_s(overall_status)} - #{message}\n"
    end

    def full_report
      output = "System Status: #{status_code_to_s(overall_status)}\n\n"
      output += to_s

      output
    end

    def to_s(indent = 0)
      indent_space = '  ' * indent

      output = "#{indent_space}#{@name}\n"
      output += "#{indent_space}#{status_code_to_s(@status_code)} - checked #{(Time.now - @timestamp).round} seconds ago.\n"
      unless @error_messages.empty?
        output += "#{indent_space}!!! #{@error_messages.join("\n#{indent_space}!!! ")}\n"
      end
      unless @all_messages.empty?
        output += "#{indent_space}#{@all_messages.join("\n#{indent_space}")}\n"
      end
      output += "\n"

      @children.each do |child|
        output += child.to_s(indent + 1)
      end

      output
    end

    def status_code_to_s(code)
      case code
      when OK then 'OK'
      when WARNING then 'WARNING'
      when CRITICAL then 'CRITICAL'
      else
        'UNKNOWN'
      end
    end

  end
end
