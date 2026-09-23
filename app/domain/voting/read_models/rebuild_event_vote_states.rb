module Voting
  module ReadModels
    class RebuildEventVoteStates
      def initialize(
        event_id:,
        event_store: Rails.configuration.event_store,
        projector: EventVoteStateProjector.new
      )
        @event_id = event_id
        @event_store = event_store
        @projector = projector
      end

      def call
        EventVoteState.where(event_id: @event_id).delete_all

        @event_store.read
          .stream("event-#{@event_id}")
          .to_a
          .select { |event| voting_event?(event) }
          .each { |event| @projector.call(event) }
      end

      private

      def voting_event?(event)
        [
          "Voting::EventUpvoted",
          "Voting::EventDownvoted"
        ].include?(event.event_type)
      end
    end
  end
end