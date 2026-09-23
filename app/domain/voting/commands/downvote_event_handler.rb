module Voting
  module Commands
    class DownvoteEventHandler
      def initialize(event_store: Rails.configuration.event_store)
        @event_store = event_store
      end

      def call(command)
        event = Voting::EventDownvoted.new(
          data: {
            event_id: command.event_id,
            user_id: command.user_id
          }
        )

        @event_store.publish(
          event,
          stream_name: "event-#{command.event_id}"
        )
      end
    end
  end
end