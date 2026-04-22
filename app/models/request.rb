class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
  validate :content_data_must_be_string_pairs

  def self.most_recent_for_source(source_app:, source_id:)
    where(source_app: source_app, source_id: source_id).order(created_at: :desc).first
  end

private

  def content_data_must_be_string_pairs
    %i[current_content previous_content].each do |content_field|
      content_hash = public_send(content_field)
      next if content_hash.nil?

      unless content_hash.is_a?(Hash)
        errors.add(content_field, "#{content_field} is not a hash")
        next
      end

      content_hash.each do |key, value|
        unless value.is_a?(String)
          errors.add(content_field, "value for #{key} must be a string")
        end
      end
    end
  end
end
