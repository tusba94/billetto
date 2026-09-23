require "test_helper"

class EventVoteStateTest < ActiveSupport::TestCase
  test "requires a user_id" do
    event = Event.create!(
      billetto_id: "test-event-1",
      title: "Test Event",
      starts_at: Time.current
    )

    vote_state = EventVoteState.new(
      event: event,
      vote: "up"
    )

    assert_not vote_state.valid?
    assert_includes vote_state.errors[:user_id], "can't be blank"
  end

  test "requires a valid vote" do
    event = Event.create!(
      billetto_id: "test-event-2",
      title: "Test Event",
      starts_at: Time.current
    )

    vote_state = EventVoteState.new(
      event: event,
      user_id: "user_test",
      vote: "invalid"
    )

    assert_not vote_state.valid?
    assert_includes vote_state.errors[:vote], "is not included in the list"
  end

  test "allows up and down votes" do
    event = Event.create!(
      billetto_id: "test-event-3",
      title: "Test Event",
      starts_at: Time.current
    )

    assert EventVoteState.new(
      event: event,
      user_id: "user_up",
      vote: "up"
    ).valid?

    assert EventVoteState.new(
      event: event,
      user_id: "user_down",
      vote: "down"
    ).valid?
  end

  test "allows only one current vote per user and event" do
    event = Event.create!(
      billetto_id: "test-event-4",
      title: "Test Event",
      starts_at: Time.current
    )

    EventVoteState.create!(
      event: event,
      user_id: "user_test",
      vote: "up"
    )

    duplicate = EventVoteState.new(
      event: event,
      user_id: "user_test",
      vote: "down"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end