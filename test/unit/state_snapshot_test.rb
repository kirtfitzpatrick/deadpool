# frozen_string_literal: true

require 'test_helper'

class StateSnapshotTest < Test::Unit::TestCase

  def setup
    @ok_state = create_state('Test', Deadpool::OK, 'Threat level is green')
    @warning_state = create_state('Test', Deadpool::WARNING, 'Threat level is orange')
    @critical_state = create_state('Test', Deadpool::CRITICAL, 'Threat level is red')

    @snapshot = Deadpool::StateSnapshot.new(@ok_state)
  end

  def test_overall_status_should_return_worst_status
    assert_equal Deadpool::OK, @snapshot.overall_status

    @snapshot.add_child(Deadpool::StateSnapshot.new(@warning_state))
    assert_equal Deadpool::WARNING, @snapshot.overall_status

    @snapshot.add_child(Deadpool::StateSnapshot.new(@critical_state))
    assert_equal Deadpool::CRITICAL, @snapshot.overall_status
  end

  def test_should_collect_all_error_messages
    assert_equal [], @snapshot.all_error_messages

    @snapshot.add_child(Deadpool::StateSnapshot.new(@warning_state))
    assert_equal ['Threat level is orange'], @snapshot.all_error_messages

    @snapshot.add_child(Deadpool::StateSnapshot.new(@critical_state))
    assert_equal ['Threat level is orange', 'Threat level is red'], @snapshot.all_error_messages
  end

  def test_should_produce_a_nagios_report
    assert_equal "OK -  last checked 0 seconds ago.\n", @snapshot.nagios_report

    @snapshot.add_child(Deadpool::StateSnapshot.new(@warning_state))
    assert @snapshot.nagios_report.include?(@warning_state.error_messages.first)
  end

  def test_should_produce_a_full_report
    assert_instance_of String, @snapshot.full_report

    @snapshot.add_child(Deadpool::StateSnapshot.new(@warning_state))
    assert_instance_of String, @snapshot.full_report
  end

  def test_status_code_to_s
    %w[OK WARNING CRITICAL].each do |c|
      assert_equal c, @snapshot.status_code_to_s(Deadpool.const_get(c))
    end
  end

  protected

  def create_state(name, code, message)
    Deadpool::State.new(name).tap do |state|
      state.set_state(code, message)
    end
  end

end
