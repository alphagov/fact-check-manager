class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, :deadline, presence: true
  validates :zendesk_number, numericality: { only_integer: true,
                                             greater_than: 999_999,
                                             message: "Zendesk number must be a number at least 7 digits long",
                                             allow_blank: true }
  validate :content_fields_are_correctly_structured

  def self.most_recent_for_source(source_app:, source_id:)
    where(source_app: source_app, source_id: source_id).order(created_at: :desc).first
  end

private

  def content_fields_are_correctly_structured
    # The structure being validated here is { "string_id": { "heading" => "string_heading": "body" => "content_string" }, ... }
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
          if content_hash.keys.sort == %w[body heading]
            heading = content_hash["heading"]
            body = content_hash["body"]

            errors.add(content_field, "heading in #{block_id} must be a string") unless heading.is_a?(String)
            errors.add(content_field, "body in #{block_id} must be a string") unless body.is_a?(String)
          else
            errors.add(content_field, "block #{block_id} must contain exactly one heading:body pair")
          end
        else
          errors.add(content_field, "value for #{block_id} must be a hash")
        end
      end
    end
  end
end
