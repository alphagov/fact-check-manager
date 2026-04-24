require "notifications/client"

module Services
  def self.publisher_api
    @publisher_api ||= GdsApi::Publisher.new(
      Plek.find("publisher"),
      bearer_token: ENV.fetch("PUBLISHER_BEARER_TOKEN", "example"),
    )
  end

  def self.notify_api
    @notify_api ||= Notifications::Client.new(notify_api_key)
  end

  private_class_method def self.notify_api_key
    # Use Rails.env as a fallback just in case GOVUK_ENVIRONMENT isn't set locally
    environment = ENV.fetch("GOVUK_ENVIRONMENT", Rails.env)

    case environment
    when "production"
      # TODO: Live key not yet created
      # ENV.fetch("GOVUK_NOTIFY_PRODUCTION_API_KEY")
    when "staging", "integration"
      ENV.fetch("GOVUK_NOTIFY_TEAM_API_KEY")
    else
      ENV.fetch("GOVUK_NOTIFY_TEST_API_KEY",
                "faketestkey-00000000-0000-0000-0000-000000000000-1b6a6cc6-15de-434a-b56e-5b5164910a2e")
    end
  end
end
