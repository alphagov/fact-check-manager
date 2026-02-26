module Services
  def self.publisher_api
    @publisher_api ||= GdsApi::Publisher.new(
      Plek.find("publisher"),
      bearer_token: ENV.fetch("PUBLISHER_BEARER_TOKEN", "example"),
    )
  end
end
