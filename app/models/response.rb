class Response < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :body, presence: true
  validates :request_id, uniqueness: { message: "has already been responded to" }
end
