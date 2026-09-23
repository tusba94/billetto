require "test_helper"

class VotingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = Event.create!(
      billetto_id: "controller-test-#{SecureRandom.uuid}",
      title: "Controller Test Event",
      starts_at: Time.current
    )
  end

  test "unauthenticated user cannot upvote" do
    post "/events/#{@event.id}/upvote"

    assert_response :unauthorized
  end

  test "unauthenticated user cannot downvote" do
    post "/events/#{@event.id}/downvote"

    assert_response :unauthorized
  end

  
end