require 'test_helper'

class HelperTest < Test::Unit::TestCase

  def test_should_configure_with_default_options
    assert_equal default_options, Deadpool::Helper.configure({ config_path: config_dir })
  end

  def default_options
    {
      pid_file: '/var/run/deadpool.pid',
      log_level: 'INFO',
      system_check_interval: 30,
      log_file: '/var/log/deadpool.log',
      admin_port: 5507,
      config_path: config_dir,
      admin_hostname: 'localhost'
    }
  end

  def config_dir
    File.expand_path('../fixtures', __dir__)
  end

end
