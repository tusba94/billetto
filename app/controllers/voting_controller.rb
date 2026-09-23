class VotingController < ApplicationController
  skip_forgery_protection

  before_action :require_authenticated_user

def upvote
  Event.find(params[:event_id])

  command = Voting::Commands::UpvoteEvent.new(
    event_id: params[:event_id].to_i,
    user_id: clerk.user_id
  )

  Rails.configuration.command_bus.call(command)

  head :no_content
end

def downvote
  Event.find(params[:event_id])

  command = Voting::Commands::DownvoteEvent.new(
    event_id: params[:event_id].to_i,
    user_id: clerk.user_id
  )

  Rails.configuration.command_bus.call(command)

  head :no_content
end

  private

  def require_authenticated_user
    return if clerk&.user?

    head :unauthorized
  end
end