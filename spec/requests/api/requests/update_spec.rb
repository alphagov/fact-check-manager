require "rails_helper"

RSpec.describe "PATCH /api/requests/:source_app/:source_id", type: :request do
  let!(:existing_request) { FactoryBot.create(:request) }

  let!(:update_payload) do
    {
      source_app: "Mainstream",
      source_id: existing_request.source_id,
      source_title: "Updated Title",
      current_content: { "part_id" => { "heading" => "heading", "body" => "Updated body goes here" } },
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
      expect(request.current_content).to eq("part_id" => { "heading" => "heading", "body" => "Updated body goes here" })
      expect(request.status).to eq("new")
      expect(request.requester_name).to eq("Malcolm Tucker")
      expect(request.requester_email).to eq("m.tucker@gov.uk")
    end

    it "updates the draft_auth_bypass_id" do
      new_auth_bypass_id = SecureRandom.uuid
      payload_with_auth_bypass = update_payload.merge(draft_auth_bypass_id: new_auth_bypass_id)

      patch "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}", params: payload_with_auth_bypass, as: :json

      expect(response).to have_http_status(:ok)
      expect(existing_request.reload.draft_auth_bypass_id).to eq(new_auth_bypass_id)
    end

    it "updates the draft_slug" do
      payload_with_slug = update_payload.merge(draft_slug: "updated-slug")

      patch "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}", params: payload_with_slug, as: :json

      expect(response).to have_http_status(:ok)
      expect(existing_request.reload.draft_slug).to eq("updated-slug")
    end
  end

  context "invalid request parameters" do
    let(:invalid_source_app) { "invalid-source-app" }
    let(:invalid_source_id) { "invalid-source-id" }

    context "invalid source_app and invalid source_id" do
      it "returns a 404" do
        patch "/api/requests/#{invalid_source_app}/#{invalid_source_id}", params: update_payload, as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{invalid_source_id} not found for app #{invalid_source_app}",
        )
      end
    end

    context "valid source_app and invalid source_id" do
      it "returns a 404" do
        patch "/api/requests/#{update_payload[:source_app]}/#{invalid_source_id}", params: update_payload, as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{invalid_source_id} not found for app #{update_payload[:source_app]}",
        )
      end
    end

    context "invalid source_app and valid source_id" do
      it "returns a 404" do
        patch "/api/requests/#{invalid_source_app}/#{update_payload[:source_id]}", params: update_payload, as: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{update_payload[:source_id]} not found for app #{invalid_source_app}",
        )
      end
    end

    context "source_app and source_id both valid, but invalid in combination" do
      let(:second_request) { FactoryBot.create(:request, source_app: "second-app") }

      it "returns a 404" do
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
        "Current content value for body must be a hash",
      )
    end
  end

  context "if current_content is not a hash" do
    let(:invalid_content_payload) { { source_app: existing_request.source_app, source_id: existing_request.source_id, current_content: "not a hash" } }

    it "returns errors for current_content format" do
      patch "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}", params: invalid_content_payload, as: :json

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)
      expect(json["errors"]).to include(
        "current_content must be a hash",
      )
    end
  end
end
