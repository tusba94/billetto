require "test_helper"

class VotingTest < ActiveSupport::TestCase
  setup do
    @event = Event.create!(
      billetto_id: "voting-test-#{SecureRandom.uuid}",
      title: "Voting Test Event",
      starts_at: Time.current
    )

    @user_id = "user_#{SecureRandom.uuid}"
  end

  test "upvote creates a domain event and updates the read model" do
    command = Voting::Commands::UpvoteEvent.new(
      event_id: @event.id,
      user_id: @user_id
    )

    Rails.configuration.command_bus.call(command)

    events = Rails.configuration.event_store
      .read
      .stream("event-#{@event.id}")
      .to_a

    assert_equal 1, events.size

    domain_event = events.first

    assert_equal "Voting::EventUpvoted", domain_event.event_type
    assert_equal @event.id, domain_event.data[:event_id]
    assert_equal @user_id, domain_event.data[:user_id]

    vote_state = EventVoteState.find_by(
      event_id: @event.id,
      user_id: @user_id
    )

    assert_equal "up", vote_state.vote
    assert_equal 1, @event.reload.upvote_count
    assert_equal 0, @event.downvote_count
  end

  test "downvote creates a domain event and updates the read model" do
    command = Voting::Commands::DownvoteEvent.new(
      event_id: @event.id,
      user_id: @user_id
    )

    Rails.configuration.command_bus.call(command)

    events = Rails.configuration.event_store
      .read
      .stream("event-#{@event.id}")
      .to_a

    assert_equal 1, events.size

    domain_event = events.first

    assert_equal "Voting::EventDownvoted", domain_event.event_type
    assert_equal @event.id, domain_event.data[:event_id]
    assert_equal @user_id, domain_event.data[:user_id]

    vote_state = EventVoteState.find_by(
      event_id: @event.id,
      user_id: @user_id
    )

    assert_equal "down", vote_state.vote
    assert_equal 0, @event.reload.upvote_count
    assert_equal 1, @event.downvote_count
  end
end