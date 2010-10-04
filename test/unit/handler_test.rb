require 'test/test_helper'

class HandlerTest < Test::Unit::TestCase

  class Deadpool::Monitor::Mock < Deadpool::Monitor::Base
  end

  class Deadpool::FailoverProtocol::Mock < Deadpool::FailoverProtocol::Base
  end

  def setup
    @config = {
      :pool_name => "test.fake",
      :monitor_config => { :monitor_class => "Mock" },
      :failover_protocol_configs => [
        { :protocol_class => "Mock" }
      ]
    }

    @logger = Logger.new("/dev/null")

    @handler = Deadpool::Handler.new(@config, @logger)
  end

  def test_monitor_instantiation
    assert_instance_of Deadpool::Monitor::Mock, @handler.instance_eval { @monitor }
  end

  def test_failover_protocal_instantiation
    assert_instance_of Deadpool::FailoverProtocol::Mock, @handler.instance_eval { @failover_protocols }.first
  end

end