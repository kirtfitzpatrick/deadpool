require 'test/test_helper'

class HelperTest < Test::Unit::TestCase
  def test_should_configure_with_default_options
    options = Deadpool::Helper.configure({:configdir => config_dir})

    assert_equal default_options, options
  end

  def default_options
    {
      :pid_file              => "/var/run/deadpool.pid",
      :log_level             => "INFO",
      :system_check_interval => 30,
      :log_file              => "/var/log/deadpool.log",
      :admin_port            => 5507,
      :configdir             => config_dir,
      :admin_hostname        => "localhost"
    }
  end

  def config_dir
    File.expand_path('../../fixtures', __FILE__)
  end
end