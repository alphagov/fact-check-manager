class Collaboration < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: {
    scope: :request_id,
    message: "is already a collaborator on this request",
  }
end
