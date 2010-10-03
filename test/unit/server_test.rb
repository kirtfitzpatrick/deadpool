require 'test/test_helper'

class ServerTest < Test::Unit::TestCase
  def test_should_have_a_clean_state
    with_server do
      assert_equal Deadpool::OK, @server.instance_eval { @state.status_code }
    end
  end

  def test_should_load_handlers
    with_server do
      handlers = @server.instance_eval { @handlers }
      assert_equal "test.database", handlers.keys.first
      assert_instance_of Deadpool::Handler, handlers["test.database"]
    end
  end

  protected

  def with_server
    configdir = File.expand_path('../../fixtures', __FILE__)

    EM.run do
      @server = Deadpool::Server.new(["--configdir=#{configdir}"])
      yield
      EM.stop
    end
  end
end