require 'test/test_helper'

class AdminTest < Test::Unit::TestCase
  def test_should_parse_commands
    argv = ["--full_report"]
    opts = Deadpool::Admin.new(argv).parse_command_line

    assert_equal :full_report, opts[:command]
  end
end