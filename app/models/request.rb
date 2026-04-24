class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
  validate :content_fields_are_correctly_structured

  def self.most_recent_for_source(source_app:, source_id:)
    where(source_app: source_app, source_id: source_id).order(created_at: :desc).first
  end

private

  def content_fields_are_correctly_structured
    # The structure being validated here is { "string_id": { "string_heading": "content_string" }, ... }
    %i[current_content previous_content].each do |content_field|
      outer_hash = public_send(content_field)
      next if outer_hash.nil?

      unless outer_hash.is_a?(Hash)
        errors.add(content_field, "#{content_field} must be a hash")
        next
      end

      outer_hash.each do |block_id, content_hash|
        errors.add(content_field, "key for #{block_id} must be a string") unless block_id.is_a?(String)
        if content_hash.is_a?(Hash)
          if content_hash.size == 1
            heading, content = content_hash.first

            errors.add(content_field, "heading in #{block_id} must be a string") unless heading.is_a?(String)
            errors.add(content_field, "content in #{block_id} must be a string") unless content.is_a?(String)
          else
            errors.add(content_field, "block #{block_id} must contain exactly one heading:content pair")
          end
        else
          errors.add(content_field, "value for #{block_id} must be a hash")
          next
        end
      end
    end
  end
end
