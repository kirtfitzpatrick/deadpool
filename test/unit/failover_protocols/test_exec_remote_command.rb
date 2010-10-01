require 'test/test_helper'

class TestDeadpoolFailoverProtocolExecRemoteCommand < Test::Unit::TestCase

  def setup
    config_file          = File.join(File.expand_path('../../..', __FILE__), 'fixtures/exec_remote_command.yml')
    @config              = YAML.load(File.read(config_file))
    @failover_config     = @config['failover_protocol_configs'].first
    @logger              = Logger.new(STDOUT)
    @logger.level        = Logger::DEBUG
    @exec_remote_command = Deadpool::FailoverProtocol::ExecRemoteCommand.new @config, @failover_config, @logger
  end

  def teardown
  end

  def test_test_client
    client  = @failover_config['client_hosts'].first
    primary = @config['primary_host']

    assert @exec_remote_command.test_client(client)
  end

  def test_preflight_check
    client  = @failover_config['client_hosts'].first
    primary = @config['primary_host']

    assert @exec_remote_command.preflight_check
  end

  def test_promote_to_primary
    client  = @failover_config['client_hosts'].first
    primary = @config['primary_host']

    assert @exec_remote_command.promote_to_primary(@config['secondary_host'])
  end

  def test_system_check
    client  = @failover_config['client_hosts'].first
    primary = @config['primary_host']

    assert @exec_remote_command.system_check.nagios_report =~ /OK/
  end

end
