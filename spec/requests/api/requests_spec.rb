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
      current_content: {
        "heading": "Some title words",
        "body": "Many lines of data for the content. Many changes that need fact checking",
      },
      previous_content: {},
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
      expect(request.current_content["body"]).to eq("Many lines of data for the content. Many changes that need fact checking")
      expect(request.status).to eq("new")
      expect(request.requester_name).to eq("GDS Content Designer")
      expect(request.requester_email).to eq("gds-content-designer@example.com")
    end
  end

  context "with an invalid payload" do
    let(:base_payload) do
      {
        source_app: "Mainstream",
        source_id: SecureRandom.uuid,
        requester_name: "GDS Content Designer",
        requester_email: "gds-content-designer@example.com",
        current_content: dynamic_current_content,
        previous_content: {},
        deadline: 1.week.from_now.iso8601,
        recipients: ["recipient1@example.com", "recipient2@example.com"],
      }
    end

    it "returns errors for missing required fields" do
      payload_missing_requesters = { requester_name: "Alice",
                                     recipients: ["recipient1@example.com", "recipient2@example.com"] }

      expect {
        post "/api/requests", params: payload_missing_requesters, as: :json
      }.to change(Request, :count).by(0)
                                  .and change(Collaboration, :count).by(0)

      expect(response).to have_http_status(:unprocessable_content)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include(
        "Source can't be blank",
        "Source app can't be blank",
        "Requester email can't be blank",
        "Current content can't be blank",
      )
    end

    context "if current_content value is not a string" do
      let(:dynamic_current_content) do
        {
          "normal_field" => "This should pass",
          "bad_number_field" => 123,
        }
      end

      it "returns an error" do
        post "/api/requests", params: base_payload, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Current content value for bad_number_field must be a string")
      end
    end

    context "if current_content contains nested data" do
      let(:dynamic_current_content) do
        {
          "normal_field" => "This should pass",
          "sneaky_nested_hash" => { "naughty" => "This should fail" },
        }
      end

      it "returns an error" do
        expect {
          post "/api/requests", params: base_payload, as: :json
        }.to change(Request, :count).by(0)
                                    .and change(Collaboration, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
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
end
