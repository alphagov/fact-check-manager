require "rails_helper"

RSpec.describe "POST /api/requests", type: :request do
  let!(:user) do
    User.create!(
      name: "FCM User",
      email: "fcm-user@example.com",
      uid: "test-uid",
    )
  end

  describe "#create" do
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
        payload_missing_required_fields = { requester_name: "Alice",
                                            recipients: ["recipient1@example.com", "recipient2@example.com"] }

        expect {
          post "/api/requests", params: payload_missing_required_fields, as: :json
        }.to change(Request, :count).by(0)
                                    .and change(Collaboration, :count).by(0)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Source can't be blank",
          "Source app can't be blank",
          "Requester email can't be blank",
          "Current content can't be blank",
          "Deadline can't be blank",
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

  describe "#resend_emails" do
    let(:existing_request) { create(:request) }

    context "valid request parameters" do
      before { expect(NotifyService).to receive(:resend_emails).and_return(true) }

      it "calls NotifyService#resend_emails" do
        post "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}/resend-emails", as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to include("id", "source_id", "source_app")
      end
    end

    context "invalid request parameters" do
      before { expect(NotifyService).not_to receive(:resend_emails) }
      let(:invalid_source_app) { "invalid-source-app" }
      let(:invalid_source_id) { "invalid-source-id" }

      context "invalid source_app and invalid source_id" do
        it "returns a 400 error" do
          post "/api/requests/#{invalid_source_app}/#{invalid_source_id}/resend-emails", as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{invalid_source_id} not found for app #{invalid_source_app}",
          )
        end
      end

      context "valid source_app and invalid source_id" do
        it "returns a 400 error" do
          post "/api/requests/#{existing_request.source_app}/#{invalid_source_id}/resend-emails", as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{invalid_source_id} not found for app #{existing_request.source_app}",
          )
        end
      end

      context "invalid source_app and valid source_id" do
        it "returns a 400 error" do
          post "/api/requests/#{invalid_source_app}/#{existing_request.source_id}/resend-emails", as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{existing_request.source_id} not found for app #{invalid_source_app}",
          )
        end
      end

      context "source_app and source_id both valid, but invalid in combination" do
        let(:existing_request_whitehall) { create(:request, source_app: "whitehall") }

        it "returns a 400 error" do
          post "/api/requests/#{existing_request_whitehall.source_app}/#{existing_request.source_id}/resend-emails", as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{existing_request.source_id} not found for app #{existing_request_whitehall.source_app}",
          )
        end
      end
    end
  end

  describe "#update" do
    let!(:existing_request) { FactoryBot.create(:request) }

    let!(:update_payload) do
      {
        source_app: "Mainstream",
        source_id: existing_request.source_id,
        source_title: "Updated Title",
        current_content: {
          "heading": "Some title words",
          "body": "Updated body goes here",
        },
      }
    end

    context "with a valid payload" do
      it "updates the Request with collaborations" do
        expect {
          patch "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}", params: update_payload, as: :json
        }.not_to change(Request, :count)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to include("id")
        expect(json).to include("source_id")
        expect(json).to include("source_app")

        request = Request.last
        expect(request.source_app).to eq("publisher")
        expect(request.source_id).to be_present
        expect(request.source_title).to eq("Updated Title")
        expect(request.current_content).to eq({ "body" => "Updated body goes here", "heading" => "Some title words" })
        expect(request.status).to eq("new")
        expect(request.requester_name).to eq("Malcolm Tucker")
        expect(request.requester_email).to eq("m.tucker@gov.uk")
      end
    end

    context "invalid request parameters" do
      let(:invalid_source_app) { "invalid-source-app" }
      let(:invalid_source_id) { "invalid-source-id" }

      describe "invalid source_app and invalid source_id" do
        it "returns a 400 error" do
          patch "/api/requests/#{invalid_source_app}/#{invalid_source_id}", params: update_payload, as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{invalid_source_id} not found for app #{invalid_source_app}",
          )
        end
      end

      describe "valid source_app and invalid source_id" do
        it "returns a 400 error" do
          patch "/api/requests/#{update_payload[:source_app]}/#{invalid_source_id}", params: update_payload, as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{invalid_source_id} not found for app #{update_payload[:source_app]}",
          )
        end
      end

      describe "invalid source_app and valid source_id" do
        it "returns a 400 error" do
          patch "/api/requests/#{invalid_source_app}/#{update_payload[:source_id]}", params: update_payload, as: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{update_payload[:source_id]} not found for app #{invalid_source_app}",
          )
        end
      end

      describe "source_app and source_id both valid, but invalid in combination" do
        let(:second_request) { FactoryBot.create(:request, source_app: "second-app") }

        it "returns a 400 error" do
          patch "/api/requests/#{second_request[:source_app]}/#{update_payload[:source_id]}", params: update_payload, as: :json
          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include(
            "Request with ID #{update_payload[:source_id]} not found for app #{second_request[:source_app]}",
          )
        end
      end
    end

    context "with an invalid payload" do
      let(:invalid_content_payload) { { source_app: existing_request.source_app, source_id: existing_request.source_id, current_content: { body: 123 } } }

      it "returns errors for missing required fields" do
        patch "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}", params: invalid_content_payload, as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Current content value for body must be a string",
        )
      end
    end
  end
end
