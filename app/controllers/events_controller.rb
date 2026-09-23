class EventsController < ApplicationController
  def index
    @signed_in = clerk&.user?
    @events = Event.order(starts_at: :asc)

    respond_to do |format|
      format.html
      format.json do
        render json: @events.map { |event| event_json(event) }
      end
    end
  end

  def show
    event = Event.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        render json: event_json(event)
      end
    end
  end

  private

  def event_json(event)
    {
      id: event.id,
      title: event.title,
      description: event.description,
      starts_at: event.starts_at,
      ends_at: event.ends_at,
      image_url: event.image_url,
      upvotes: event.upvote_count,
      downvotes: event.downvote_count
    }
  end
end