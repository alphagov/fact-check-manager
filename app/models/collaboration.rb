class Collaboration < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :request, presence: true
  validates :role, presence: true
  validates :user, presence: true, uniqueness: {
    scope: :request_id,
    message: "is already a collaborator on this request",
  }
end
