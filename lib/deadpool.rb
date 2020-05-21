require 'rubygems'
require 'eventmachine'
require 'logger'
require 'yaml'

# TODO: can this be avoided?
$:.unshift File.dirname(__FILE__)

module Deadpool
  OK = 0
  WARNING = 1
  CRITICAL = 2
  UNKNOWN = 3

  class DeadpoolError < StandardError; end

  autoload :Version, 'deadpool/version'
  autoload :Admin, 'deadpool/admin'
  autoload :CommandServer, 'deadpool/command_server'
  autoload :Daemonizer, 'deadpool/daemonizer'
  autoload :Handler, 'deadpool/handler'
  autoload :Helper, 'deadpool/helper'
  autoload :Options, 'deadpool/options'
  autoload :ScriptOption, 'deadpool/script_option'
  autoload :State, 'deadpool/state'
  autoload :StateSnapshot, 'deadpool/state_snapshot'
  autoload :Server, 'deadpool/server'

  module Generator
    autoload :Base, 'deadpool/generator/base'
    autoload :UpstartConfig, 'deadpool/generator/upstart_config'
    autoload :DeadpoolConfig, 'deadpool/generator/deadpool_config'
  end

  module Monitor
    autoload :Base, 'deadpool/monitor/base'
    autoload :Mysql, 'deadpool/monitor/mysql'
    autoload :GenericNagios, 'deadpool/monitor/generic_nagios'
  end

  module FailoverProtocol
    autoload :Base, 'deadpool/failover_protocol/base'
    autoload :EtcHosts, 'deadpool/failover_protocol/etc_hosts'
    autoload :ExecRemoteCommand, 'deadpool/failover_protocol/exec_remote_command'
  end
end
