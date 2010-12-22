require 'test/test_helper'

class StateTest < Test::Unit::TestCase
  def setup
    @state = Deadpool::State.new "Test", StateTest
  end

  def test_should_initialize_with_clean_state
    assert_equal "Test - StateTest", @state.name
    assert_equal Deadpool::OK, @state.status_code
    assert_equal [], @state.error_messages
    assert_equal [], @state.all_messages
  end

  def test_should_set_state_to_warning
    @state.set_state(Deadpool::WARNING, "Threat level is orange")

    assert_equal Deadpool::WARNING, @state.status_code
    assert_equal "Threat level is orange", @state.error_messages.first
    assert_equal [], @state.all_messages
  end

  def test_should_set_state_to_ok
    @state.set_state(Deadpool::OK, "Everything is cool")

    assert_equal Deadpool::OK, @state.status_code
    assert_equal [], @state.error_messages
    assert_equal "Everything is cool", @state.all_messages.first
  end

  def test_should_not_set_state_when_locked
    @state.lock
    @state.set_state(Deadpool::WARNING, "Threat level is orange, but state is locked")

    assert_equal Deadpool::OK, @state.status_code
    assert_equal [], @state.error_messages
    assert_equal [], @state.all_messages
  end

  def test_should_reset_state
    @state.set_state(Deadpool::WARNING, "Threat level is orange")
    @state.reset!

    assert_equal Deadpool::OK, @state.status_code
  end

  def test_should_escalate_status_code
    @state.escalate_status_code Deadpool::WARNING

    assert_equal Deadpool::WARNING, @state.status_code
  end

  def test_should_not_escalate_to_lower_status_code
    @state.set_state(Deadpool::CRITICAL, "Threat level is red")
    @state.escalate_status_code Deadpool::WARNING

    assert_equal Deadpool::CRITICAL, @state.status_code
  end

  def test_should_add_message
    @state.add_message "A message"
    assert_equal "A message", @state.all_messages.first
  end

  def test_should_add_error_message
    @state.add_error_message "An error message"
    assert_equal "An error message", @state.error_messages.first
  end
end