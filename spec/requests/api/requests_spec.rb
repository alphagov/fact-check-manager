require "rails_helper"

RSpec.describe "POST /api/requests", type: :request do
  let!(:user) do
    User.create!(
      name: "FCM User",
      email: "fcm-user@example.com",
      uid: "test-uid",
    )
  end

  let!(:valid_payload) do
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

  context "create" do
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

  context "update" do
    let!(:existing_request) { Request.create!(valid_payload.except(:recipients)) }

    let!(:update_payload) do
      {
        source_app: "Mainstream",
        source_id: existing_request.source_id,
        source_title: "Updated Title",
        current_content: "<p>Updated HTML goes here</p>",
      }
    end

    context "with a valid payload" do
      it "creates updates the Request with collaborations" do
        expect {
          patch "/api/requests/#{valid_payload[:source_app]}/#{valid_payload[:source_id]}", params: update_payload, as: :json
        }.not_to change(Request, :count)

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to include("id")
        expect(json).to include("source_id")
        expect(json).to include("source_app")

        request = Request.last
        expect(request.source_app).to eq("Mainstream")
        expect(request.source_id).to be_present
        expect(request.source_title).to eq("Updated Title")
        expect(request.current_content).to eq("<p>Updated HTML goes here</p>")
        expect(request.current_content).not_to eq("<p>Test HTML</p>")
        expect(request.status).to eq("new")
        expect(request.requester_name).to eq("GDS Content Designer")
        expect(request.requester_email).to eq("gds-content-designer@example.com")
      end

      context "invalid request parameters" do
        describe "invalid source_app and invalid source_id" do
          it "returns a 400 error" do
            update_payload[:source_id] = 9_999_999_999
            update_payload[:source_app] = "not-a-real-source-app"
            patch "/api/requests/#{update_payload[:source_app]}/#{update_payload[:source_id]}", params: update_payload, as: :json

            expect(response).to have_http_status(:bad_request)
            json = JSON.parse(response.body)
            expect(json["errors"]).to include(
              "Request with ID #{update_payload[:source_id]} not found for app #{update_payload[:source_app]}",
            )
          end
        end

        describe "valid source_app and invalid source_id" do
          it "returns a 400 error" do
            update_payload[:source_id] = 9_999_999_999
            patch "/api/requests/#{update_payload[:source_app]}/#{update_payload[:source_id]}", params: update_payload, as: :json

            expect(response).to have_http_status(:bad_request)
            json = JSON.parse(response.body)
            expect(json["errors"]).to include(
              "Request with ID #{update_payload[:source_id]} not found for app #{update_payload[:source_app]}",
            )
          end
        end

        describe "invalid source_app and valid source_id" do
          it "returns a 400 error" do
            update_payload[:source_app] = "not-a-real-source-app"
            patch "/api/requests/#{update_payload[:source_app]}/#{update_payload[:source_id]}", params: update_payload, as: :json

            expect(response).to have_http_status(:bad_request)
            json = JSON.parse(response.body)
            expect(json["errors"]).to include(
              "Request with ID #{update_payload[:source_id]} not found for app #{update_payload[:source_app]}",
            )
          end
        end

        describe "source_app and source_id both valid, but invalid in combination" do
          let(:second_payload) do
            {
              source_app: "second-app",
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
          let(:second_request) { Request.create!(second_payload.except(:recipients)) }

          it "returns a 400 error" do
            patch "/api/requests/#{second_payload[:source_app]}/#{update_payload[:source_id]}", params: update_payload, as: :json

            expect(response).to have_http_status(:bad_request)
            json = JSON.parse(response.body)
            expect(json["errors"]).to include(
              "Request with ID #{update_payload[:source_id]} not found for app #{second_payload[:source_app]}",
            )
          end
        end
      end
    end

    context "with an invalid payload" do
      it "returns errors for missing required fields" do
        invalid_payload = { source_app: existing_request.source_app, source_id: existing_request.source_id, current_content: "" }

        patch "/api/requests/#{invalid_payload[:source_app]}/#{invalid_payload[:source_id]}", params: invalid_payload, as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Current content can't be blank",
        )
      end
    end
  end
end
