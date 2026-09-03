class Request < ApplicationRecord
  has_many :collaborations, dependent: :destroy
  has_many :users, through: :collaborations
  has_one :response

  ZENDESK_NUMBER_REGEX = /\A\d{7,}\z/
  ALLOWED_SCHEMES = %w[http https].freeze

  normalizes :zendesk_number, with: ->(value) { value.presence }

  validates :source_id, :source_app, :requester_name, :requester_email, :status, :current_content, presence: true
  validates :deadline,
            presence: true,
            comparison: {
              greater_than: -> { Time.zone.now },
              less_than: -> { 10.years.from_now },
              message: "must be a date between now and 10 years in the future",
            }
  validates :requester_email,
            presence: true,
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: "must be a valid email address",
            }
  validate :requester_email_has_tld

  validates :source_url,
            allow_blank: true,
            format: {
              with: URI::DEFAULT_PARSER.make_regexp,
              message: "must be a valid URL",
            }

  validate :source_url_uses_allowed_scheme

  validate :content_fields_are_correctly_structured
  validate :valid_zendesk_number

  def self.most_recent_for_source(source_app:, source_id:)
    where(source_app: source_app, source_id: source_id).order(created_at: :desc).first
  end

  def formatted_deadline
    deadline.strftime("%A %-e %B %Y")
  end

  def first_edition?
    previous_content.blank?
  end

private

  def source_url_uses_allowed_scheme
    return if source_url.blank?
    return if ALLOWED_SCHEMES.include?(URI.parse(source_url.to_s).scheme)

    errors.add(:source_url, "must use either http or https")
  rescue URI::InvalidURIError
    errors.add(:source_url, "must be a valid URL")
  end

  def requester_email_has_tld
    domain = requester_email.to_s.split("@").last
    return if domain&.include?(".")

    errors.add(:requester_email, "must be a valid email address")
  end

  def valid_zendesk_number
    return if zendesk_number.blank?

    if !zendesk_number.match?(ZENDESK_NUMBER_REGEX)
      errors.add(:zendesk_number, "must be at least 7 digits long")
    elsif zendesk_number.start_with?("0")
      errors.add(:zendesk_number, "cannot start with zero")
    end
  end

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
