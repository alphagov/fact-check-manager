class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :edition_id, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
  scope :for_edition, ->(edition_id) { where(edition_id: edition_id) }
  scope :most_recent_first, -> { order(created_at: :desc) }
  scope :most_recent_for_edition, ->(edition_id) { for_edition(edition_id).most_recent_first.first }
end
