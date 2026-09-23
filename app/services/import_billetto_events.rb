class ImportBillettoEvents
  def initialize(client: Billetto::Client.new)
    @client = client
  end

  def call
    events = @client.fetch_events

    events.each do |event_data|
      import_event(event_data)
    end
  end

  private

  def import_event(event_data)
    event = Event.find_or_initialize_by(
      billetto_id: event_data[:billetto_id]
    )

    event.assign_attributes(
      title: event_data[:title],
      description: event_data[:description],
      starts_at: event_data[:starts_at],
      ends_at: event_data[:ends_at],
      image_url: event_data[:image_url],
      metadata: event_data[:metadata]
    )

    event.save!
 end
end