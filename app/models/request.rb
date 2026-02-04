class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
  scope :for_source, ->(source_id) { where(source_id: source_id) }
  scope :most_recent_first, -> { order(created_at: :desc) }
  scope :most_recent_for_source, ->(source_id) { for_source(source_id).most_recent_first.first }
end
