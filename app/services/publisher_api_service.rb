class PublisherApiService
  def self.post_fact_check_response(response)
    Services.publisher_api.post_fact_check_response(**payload(response))
  end

  def self.payload(response)
    {
      edition_id: response.request.source_id,
      responder_name: response.user.name,
      accepted: response.accepted,
      comment: response.body,
    }
  end
end
