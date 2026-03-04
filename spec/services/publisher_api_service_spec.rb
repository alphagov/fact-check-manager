require "rails_helper"

RSpec.describe PublisherApiService do
  before do
    stub_fact_check_response_posts

    request = FactoryBot.build(:request)
    user = FactoryBot.create(:user, name: "Douglas Adams")

    @service = described_class
    @response = FactoryBot.build(:response, request: request, user: user, accepted: true, body: "Custom message")
  end

  context "#post_fact_check_response" do
    it "calls the Publisher api adapter with the correct arguments" do
      @service.post_fact_check_response(@response)

      expect(Services.publisher_api).to have_received(:post_fact_check_response).with(
        {
          edition_id: @response.request.source_id,
          responder_name: "Douglas Adams",
          accepted: true,
          comment: "Custom message",
        },
      )
    end
  end
end
