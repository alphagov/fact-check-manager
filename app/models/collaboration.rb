class Collaboration < ApplicationRecord
  belongs_to :request
  belongs_to :user

  validates :role, presence: true
end
