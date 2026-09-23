class EventVoteState < ApplicationRecord
  belongs_to :event

  VOTES = %w[up down].freeze

  validates :user_id, presence: true
  validates :vote, presence: true, inclusion: { in: VOTES }
  validates :user_id, uniqueness: { scope: :event_id }
end