require 'test_helper'

class MockServer

  include Deadpool::CommandServer

  def send_data(data)
    @data = data
  end

  def last_sent_data
    @data
  end

  def close_connection_after_writing; end

end

class MockDeadpoolServer

  attr_reader :logger

  def initialize
    @logger = Logger.new('/dev/null')
  end

  def system_check(_force = false)
    MockStateSnapshot.new
  end

  def promote(pool, server)
    (!pool.nil? && !server.nil?)
  end

end

class MockStateSnapshot

  def full_report
    'Full Report'
  end

  def nagios_report
    'Nagios Report'
  end

end

class CommandServerTest < Test::Unit::TestCase

  def setup
    @command_server = MockServer.new
    @command_server.deadpool_server = MockDeadpoolServer.new
  end

  def teardown; end

  def test_full_report
    json_data = JSON.dump command: 'full_report'
    @command_server.receive_data(json_data)
    assert_equal 'Full Report', @command_server.last_sent_data
  end

  def test_nagios_report
    json_data = JSON.dump command: 'nagios_report'
    @command_server.receive_data(json_data)
    assert_equal 'Nagios Report', @command_server.last_sent_data
  end

  def test_promote
    json_data = JSON.dump command: 'promote', pool: 'success', server: 'servername'
    @command_server.receive_data(json_data)
    assert_equal "Success.\n", @command_server.last_sent_data

    json_data = JSON.dump command: 'promote', pool: nil, server: 'servername'
    @command_server.receive_data(json_data)
    assert_equal "Failed!\n", @command_server.last_sent_data
  end

  def test_bad_command
    json_data = JSON.dump command: 'unrecognized_command'
    @command_server.receive_data(json_data)
    assert_equal 'Server did not understand the command.', @command_server.last_sent_data
  end

end
