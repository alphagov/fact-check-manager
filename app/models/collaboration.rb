class Collaboration < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :user, presence: true
  validates :request, presence: true
  validates :user, uniqueness: {
    scope: :request_id,
    message: "duplicate recipient specified",
  }
  validates :role, presence: true
end
