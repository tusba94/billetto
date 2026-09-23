module Billetto
  class FakeClient
    def fetch_events(limit: 10)
      [
        {
          billetto_id: "billetto-001",
          title: "Live Music Festival",
          description: "A live music event featuring multiple artists.",
          starts_at: Time.zone.parse("2026-10-10 18:00:00"),
          ends_at: Time.zone.parse("2026-10-10 23:00:00"),
          image_url: "https://example.com/events/music-festival.jpg",
          metadata: {
            source: "billetto",
            category: "music"
          }
        },
        {
          billetto_id: "billetto-002",
          title: "Tech Conference 2026",
          description: "Technology and software engineering conference.",
          starts_at: Time.zone.parse("2026-11-15 09:00:00"),
          ends_at: Time.zone.parse("2026-11-15 18:00:00"),
          image_url: "https://example.com/events/tech-conference.jpg",
          metadata: {
            source: "billetto",
            category: "technology"
          }
        }
      ].first(limit)
    end
  end
end