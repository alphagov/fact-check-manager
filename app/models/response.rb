class Response < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :body,
            presence: {
              message: "cannot be blank if accepted is false",
            }, unless: :accepted
  validates :request_id, uniqueness: { message: "has already been responded to" }
  validates :accepted, inclusion: { in: [true, false], message: "must be true or false" }
end
