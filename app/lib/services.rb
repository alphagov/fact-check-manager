require "notifications/client"

module Services
  class NotifyStub
    def method_missing(_name, *_args, &_block)
      true
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end

  def self.publisher_api
    @publisher_api ||= GdsApi::Publisher.new(
      Plek.find("publisher"),
      bearer_token: ENV.fetch("PUBLISHER_BEARER_TOKEN", "example"),
    )
  end

  def self.notify_api
    @notify_api ||= if Rails.env.development?
                      NotifyStub.new
                    else
                      Notifications::Client.new(
                        ENV.fetch("GOVUK_NOTIFY_API_KEY", nil),
                      )
                    end
  end
end
