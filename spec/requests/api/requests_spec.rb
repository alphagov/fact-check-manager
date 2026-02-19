require "rails_helper"

RSpec.describe "POST /api/requests", type: :request do
  let!(:user) do
    User.create!(
      name: "FCM User",
      email: "fcm-user@example.com",
      uid: "test-uid",
    )
  end

  let(:valid_payload) do
    {
      source_app: "Mainstream",
      source_id: SecureRandom.uuid,
      source_url: "",
      source_title: "",
      requester_name: "GDS Content Designer",
      requester_email: "gds-content-designer@example.com",
      current_content: "<p>Test HTML</p>",
      previous_content: "",
      deadline: 1.week.from_now.iso8601,
      recipients: ["recipient1@example.com", "recipient2@example.com"],
    }
  end

  context "with a valid payload" do
    it "creates a new Request with collaborations" do
      expect {
        post "/api/requests", params: valid_payload, as: :json
      }.to change(Request, :count).by(1)
       .and change(Collaboration, :count).by(2)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json).to include("id")

      request = Request.last
      expect(request.source_app).to eq("Mainstream")
      expect(request.source_id).to be_present
      expect(request.current_content).to eq("<p>Test HTML</p>")
      expect(request.status).to eq("new")
      expect(request.requester_name).to eq("GDS Content Designer")
      expect(request.requester_email).to eq("gds-content-designer@example.com")
    end
  end

  context "with invalid payload" do
    it "returns errors for missing required fields" do
      invalid_payload = { requester_name: "Alice", recipients: ["recipient1@example.com", "recipient2@example.com"] }

      post "/api/requests", params: invalid_payload, as: :json

      expect(response).to have_http_status(:bad_request)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include(
        "Source can't be blank",
        "Requester email can't be blank",
      )
    end
  end

  context "without recipients" do
    it "returns a 400 error" do
      payload = valid_payload
      payload.delete(:recipients)

      post "/api/requests", params: payload, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)["errors"])
        .to include("At least one recipient email is required")
    end
  end
end
