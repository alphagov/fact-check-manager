require "rails_helper"
require "notifications/client"

# Only Signon API users with the `internal_app` permission, such as
# Publisher's, can use the API.
RSpec.describe "API authorisation", type: :request do
  let(:notify_client_spy) { instance_spy(Notifications::Client) }
  let(:existing_request) do
    create(:request, source_title: "Original title").tap do |request|
      create(:collaboration, user: create(:user, email: "recipient@example.com"), request:, role: "fact_checker")
    end
  end
  let(:create_payload) do
    {
      source_app: "publisher",
      source_id: SecureRandom.uuid,
      requester_name: "Requester",
      requester_email: "requester@example.com",
      current_content: { "part_id" => { "heading" => "heading", "body" => "Content to fact check" } },
      previous_content: {},
      reason_for_change: "a reason",
      zendesk_number: "1234567",
      deadline: 1.week.from_now.iso8601,
      recipients: %w[recipient@example.com],
    }
  end
  let(:request_path) { "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}" }

  before { allow(Services).to receive(:notify_api).and_return(notify_client_spy) }

  context "when the user has the internal_app permission" do
    before { GDS::SSO.test_user = create(:user, permissions: %w[signin internal_app]) }

    it "allows creating a request" do
      post "/api/requests", params: create_payload, as: :json

      expect(response).to have_http_status(:created)
    end

    it "allows updating a request" do
      patch request_path, params: { source_title: "Changed title" }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "allows resending emails" do
      post "#{request_path}/resend-emails", as: :json

      expect(response).to have_http_status(:ok)
      expect(notify_client_spy).to have_received(:send_email)
    end
  end

  context "when the user does not have the internal_app permission" do
    before { GDS::SSO.test_user = create(:user, permissions: %w[signin]) }

    it "refuses to create a request" do
      expect { post "/api/requests", params: create_payload, as: :json }.not_to change(Request, :count)

      expect(response).to have_http_status(:forbidden)
      expect(notify_client_spy).not_to have_received(:send_email)
    end

    it "refuses to update a request" do
      patch request_path, params: { source_title: "Changed title" }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(existing_request.reload.source_title).to eq("Original title")
    end

    it "refuses to resend emails" do
      post "#{request_path}/resend-emails", as: :json

      expect(response).to have_http_status(:forbidden)
      expect(notify_client_spy).not_to have_received(:send_email)
    end
  end
end
