class Response < ApplicationRecord
  BODY_MAX_LENGTH = 9000

  belongs_to :request
  belongs_to :user

  validates :body,
            presence: {
              message: "cannot be blank if accepted is false",
            }, unless: :accepted
  validates :body, length: { maximum: BODY_MAX_LENGTH, message: "length must be a maximum of %{count} characters" }
  validates :request_id, uniqueness: { message: "has already been responded to" }
  validates :accepted, inclusion: { in: [true, false], message: "must be true or false" }
end
