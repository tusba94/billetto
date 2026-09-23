class Event < ApplicationRecord
  has_many :event_vote_states, dependent: :destroy

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :billetto_id, presence: true, uniqueness: true

  def upvote_count
    event_vote_states.where(vote: "up").count
  end

  def downvote_count
    event_vote_states.where(vote: "down").count
  end
end