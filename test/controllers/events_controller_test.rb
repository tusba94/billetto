require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = Event.create!(
      billetto_id: "test-event-001",
      title: "Test Event",
      description: "Test description",
      starts_at: Time.current
    )
  end

  test "should get index" do
    get events_url

    assert_response :success
  end

  test "should get show" do
    get event_url(@event)

    assert_response :success
  end
end