class Response < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :body,
            presence: {
              message: "cannot be blank if accepted is false",
            }, unless: :accepted
  validate :body_has_max_length_9000
  validates :request_id, uniqueness: { message: "has already been responded to" }
  validates :accepted, inclusion: { in: [true, false], message: "must be true or false" }

private

  def body_has_max_length_9000
    return if body.blank?

    errors.add(:body, "length must be a maximum of 9000 characters") if body.length > 9000
  end
end
