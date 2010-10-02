require 'test/test_helper'

class StateSnapshotTest < Test::Unit::TestCase
  def setup
    @ok_state       = create_state("Test", Deadpool::OK,      "Threat level is green")
    @warning_state  = create_state("Test", Deadpool::WARNING,  "Threat level is orange")
    @critical_state = create_state("Test", Deadpool::CRITICAL, "Threat level is red")

    @snapshot = Deadpool::StateSnapshot.new(@ok_state)
  end

  def test_overall_status_should_return_worst_status
    assert_equal Deadpool::OK, @snapshot.overall_status

    @snapshot.add_child( Deadpool::StateSnapshot.new(@warning_state) )
    assert_equal Deadpool::WARNING, @snapshot.overall_status

    @snapshot.add_child( Deadpool::StateSnapshot.new(@critical_state) )
    assert_equal Deadpool::CRITICAL, @snapshot.overall_status
  end

  def create_state(name, code, message)
    Deadpool::State.new(name).tap do |state|
      state.set_state(code, message)
    end
  end
end