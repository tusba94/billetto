require "test_helper"

class ImportBillettoEventsTest < ActiveSupport::TestCase
  test "imports events from Billetto" do
    client = Billetto::FakeClient.new

    assert_difference("Event.count", 2) do
      ImportBillettoEvents.new(client: client).call
    end

    event = Event.find_by(billetto_id: "billetto-001")

    assert_equal "Live Music Festival", event.title
    assert_equal "A live music event featuring multiple artists.", event.description
    assert_equal "https://example.com/events/music-festival.jpg", event.image_url
    assert_equal "music", event.metadata["category"]
  end

  test "does not create duplicates when importing the same events again" do
    client = Billetto::FakeClient.new
    service = ImportBillettoEvents.new(client: client)

    service.call

    assert_no_difference("Event.count") do
      service.call
    end
  end
end