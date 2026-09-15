class Response < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :accepted, inclusion: { in: [true, false], message: :not_boolean }
  validates :body, presence: true,
                   length: { maximum: 9000, message: :too_long },
                   if: -> { accepted == false }
  validates :request_id, uniqueness: { message: :not_unique }
end
