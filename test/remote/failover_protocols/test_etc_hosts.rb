require 'test/test_helper'

class TestDeadpoolFailoverProtocolEtcHosts < Test::Unit::TestCase

  def setup
    app_root                        = File.expand_path('../../../..', __FILE__)
    config_file                     = File.join(app_root, 'test', 'fixtures/etc_hosts.yml')
    @config                         = YAML.load(File.read(config_file))
    @failover_config                = @config['failover_protocol_configs'].first
    @failover_config['script_path'] = File.join(app_root, 'bin', 'etc_hosts_switch')
    @logger                         = Logger.new(STDOUT)
    @logger.level                   = Logger::DEBUG
    @etc_hosts                      = Deadpool::FailoverProtocol::EtcHosts.new @config, @failover_config, @logger
  end

  def teardown
  end

  def test_all
    client  = @failover_config['client_hosts'].first
    primary = @config['primary_host']

    assert(@etc_hosts.test_client(client), "Test Client")
    assert(@etc_hosts.promote_to_primary_on_client(client, @config['primary_host']), "Assign Primary On Client")
    assert(@etc_hosts.verify_client(client), "Verify Client")
    assert(@etc_hosts.preflight_check, "Preflight Check")

    assert(@etc_hosts.promote_to_primary_on_client(client, @config['secondary_host']), "Assign Secondary On Client")
    assert_equal(false, @etc_hosts.verify_client(client), "Verify Client")
  end

end
