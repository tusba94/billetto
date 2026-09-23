module Voting
  module ReadModels
    class EventVoteStateProjector
      def call(event)
        vote_state = EventVoteState.find_or_initialize_by(
          event_id: event.data.fetch(:event_id),
          user_id: event.data.fetch(:user_id)
        )

        vote_state.vote =
          case event
          when Voting::EventUpvoted
            "up"
          when Voting::EventDownvoted
            "down"
          else
            return
          end

        vote_state.save!
      end
    end
  end
end