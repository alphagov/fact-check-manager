class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :edition_id, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
end
