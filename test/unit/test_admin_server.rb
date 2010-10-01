require 'test/test_helper'

class MockServer
  include Deadpool::AdminServer

  def send_data(data)
    @data = data
  end

  def last_sent_data
    return @data
  end

  def close_connection_after_writing
  end

end

class MockDeadpoolServer
  
  attr_accessor :logger
  
  def initialize
    @logger = Logger.new STDOUT
  end
  
  def system_check(force=false)
    return MockStateSnapshot.new
  end

  def promote_server(pool, server)
    return (!pool.nil? and !server.nil?)
  end
  
end

class MockStateSnapshot

  def full_report
    return "Full Report"
  end

  def nagios_report
    return "Nagios Report"
  end

end


class TestDeadpoolAdminServer < Test::Unit::TestCase

  def setup
    @admin_server                 = MockServer.new
    @admin_server.deadpool_server = MockDeadpoolServer.new
  end

  def teardown
  end

  def test_full_report
    json_data = JSON.dump :command => 'full_report'
    @admin_server.receive_data(json_data)
    assert_equal 'Full Report', @admin_server.last_sent_data
  end
  
  def test_nagios_report
    json_data = JSON.dump :command => 'nagios_report'
    @admin_server.receive_data(json_data)
    assert_equal 'Nagios Report', @admin_server.last_sent_data
  end
  
  def test_promote_server
    json_data = JSON.dump :command => 'promote_server', :pool => 'success', :server => 'servername'
    @admin_server.receive_data(json_data)
    assert_equal "Success.\n", @admin_server.last_sent_data

    json_data = JSON.dump :command => 'promote_server', :pool => nil, :server => 'servername'
    @admin_server.receive_data(json_data)
    assert_equal "Failed!\n", @admin_server.last_sent_data
  end
  
  def test_bad_command
    json_data = JSON.dump :command => 'unrecognized_command'
    @admin_server.receive_data(json_data)
    assert_equal "Server did not understand the command.", @admin_server.last_sent_data
  end

end
