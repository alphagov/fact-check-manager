class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, presence: true
  validate :content_data_must_be_string_pairs

  scope :for_source, ->(source_id) { where(source_id: source_id) }
  scope :most_recent_first, -> { order(created_at: :desc) }
  scope :most_recent_for_source, ->(source_id) { for_source(source_id).most_recent_first.first }

  def content_data_must_be_string_pairs
    fields_to_test = %i[current_content previous_content].select { |f| self[f].present? }

    fields_to_test.each do |content_field|
      content_hash = public_send(content_field)
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
