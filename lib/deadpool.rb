
require 'rubygems'
require 'eventmachine'
require 'logger'
require 'yaml'

$:.unshift File.dirname(__FILE__)


module Deadpool
  OK       = 0
  WARNING  = 1
  CRITICAL = 2
  UNKNOWN  = 3

  autoload :Admin,                'deadpool/admin'
  autoload :AdminServer,          'deadpool/admin_server'
  autoload :CommandLineServer,    'deadpool/command_line_server'
  autoload :Daemonizer,           'deadpool/daemonizer'
  autoload :Generator,            'deadpool/generator'
  autoload :Handler,              'deadpool/handler'
  autoload :Helper,               'deadpool/helper'
  autoload :Options,              'deadpool/options'
  autoload :State,                'deadpool/state'
  autoload :StateSnapshot,        'deadpool/state_snapshot'
  autoload :Server,               'deadpool/server'


  module FailoverProtocol
    autoload :Base,               'deadpool/failover_protocol'
  end

  module Monitor
    autoload :Base,               'deadpool/monitor/base'
    autoload :Mysql,              'deadpool/monitor/mysql'
    autoload :GenericNagios,      'deadpool/monitor/generic_nagios'
  end

  module FailoverProtocol
    autoload :EtcHosts,           'deadpool/failover_protocol/etc_hosts'
    autoload :ExecRemoteCommand,  'deadpool/failover_protocol/exec_remote_command'
  end

  class DeadpoolError < StandardError; end
end
