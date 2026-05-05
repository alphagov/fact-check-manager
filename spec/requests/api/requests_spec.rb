require "rails_helper"
require "notifications/client"

RSpec.describe "POST /api/requests", type: :request do
  before do
    @notify_client_spy = instance_spy(Notifications::Client)
    allow(Services).to receive(:notify_api).and_return(@notify_client_spy)
  end

  describe "#create" do
    let(:draft_content_id) { SecureRandom.uuid }
    let(:draft_auth_bypass_id) { SecureRandom.uuid }

    let(:valid_payload) do
      {
        source_app: "Mainstream",
        source_id: SecureRandom.uuid,
        source_url: "",
        source_title: "",
        requester_name: "GDS Content Designer",
        requester_email: "gds-content-designer@example.com",
        current_content: { "part_id" => {
          "heading" => "heading", "body" => "Many lines of data for the content. Many changes that need fact checking"
        } },
        previous_content: {},
        reason_for_change: "a reason",
        zendesk_number: 1_234_567,
        deadline: 1.week.from_now.iso8601,
        recipients: ["recipient1@example.com", "recipient2@example.com"],
        draft_content_id:,
        draft_auth_bypass_id:,
        draft_slug: "test-edition-slug",
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
        expect(request.current_content["part_id"]["body"]).to eq("Many lines of data for the content. Many changes that need fact checking")
        expect(request.status).to eq("new")
        expect(request.requester_name).to eq("GDS Content Designer")
        expect(request.requester_email).to eq("gds-content-designer@example.com")
        expect(request.reason_for_change).to eq("a reason")
        expect(request.zendesk_number).to eq(1_234_567)
        expect(request.draft_content_id).to eq(draft_content_id)
        expect(request.draft_auth_bypass_id).to eq(draft_auth_bypass_id)
        expect(request.draft_slug).to eq("test-edition-slug")
      end

      it "creates a Request without zendesk_number" do
        payload_without_zendesk = valid_payload.except(:zendesk_number)

        expect {
          post "/api/requests", params: payload_without_zendesk, as: :json
        }.to change(Request, :count).by(1)

        expect(response).to have_http_status(:created)

        request = Request.last
        expect(request.zendesk_number).to be_nil
      end

      it "creates a Request without reason_for_change" do
        payload_without_zendesk = valid_payload.except(:reason_for_change)

        expect {
          post "/api/requests", params: payload_without_zendesk, as: :json
        }.to change(Request, :count).by(1)

        expect(response).to have_http_status(:created)

        request = Request.last
        expect(request.reason_for_change).to be_nil
      end

      it "creates a Request without draft fields" do
        payload_without_draft = valid_payload.except(:draft_content_id, :draft_auth_bypass_id, :draft_slug)

        expect {
          post "/api/requests", params: payload_without_draft, as: :json
        }.to change(Request, :count).by(1)

        expect(response).to have_http_status(:created)

        request = Request.last
        expect(request.draft_content_id).to be_nil
        expect(request.draft_auth_bypass_id).to be_nil
        expect(request.draft_slug).to be_nil
      end

      it "creates a user record for given email address when one does not already exist" do
        expect {
          post "/api/requests", params: valid_payload, as: :json
        }.to change(User, :count).by(2)

        expect(User.second_to_last.email).to eq("recipient1@example.com")
        expect(User.last.email).to eq("recipient2@example.com")
      end

      it "does not create any new user records if they already exist for given email addresses" do
        recipient1_email = "recipient1@example.com"
        recipient1 = create(:user, email: recipient1_email)

        expect {
          post "/api/requests", params: valid_payload, as: :json
        }.to change(User, :count).by(1)

        expect(User.find_by(email: recipient1_email).id).to eq(recipient1.id)
        expect(User.where(email: recipient1_email).count).to eq(1)
      end

      it "creates a user record which contains only the email, ID, timestamps and defaults" do
        post "/api/requests", params: valid_payload, as: :json

        populated_attributes = User.last.attributes.compact.keys
        expect(populated_attributes).to contain_exactly(
          "email",
          "id",
          "created_at",
          "updated_at",
          "disabled",
          "permissions",
          "remotely_signed_out",
        )
      end

      it "does not alter any existing user records" do
        recipient1_email = "recipient1@example.com"
        recipient1 = create(:user, email: recipient1_email)

        expect {
          post "/api/requests", params: valid_payload, as: :json
        }.not_to(change { recipient1.reload.updated_at })
      end

      context "Notify" do
        context "successfully sends emails" do
          it "to each recipient" do
            allow(@notify_client_spy).to receive(:send_email)

            expect {
              post "/api/requests", params: valid_payload, as: :json
            }.to change(Request, :count).by(1)

            expect(response).to have_http_status(:created)
            expect(@notify_client_spy).to have_received(:send_email).exactly(2).times
            expect(@notify_client_spy).to have_received(:send_email).with(hash_including(email_address: "recipient1@example.com"))
            expect(@notify_client_spy).to have_received(:send_email).with(hash_including(email_address: "recipient2@example.com"))
          end
        end

        context "returns an error" do
          it "returns a bad gateway response for general error" do
            fake_response = double("response", code: 500, body: "Simulated Notify Error")
            specific_error = Notifications::Client::RequestError.new(fake_response)
            allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)

            expect {
              post "/api/requests", params: valid_payload, as: :json
            }.to change(Request, :count).by(1)

            expect(response).to have_http_status(:bad_gateway)
            json = JSON.parse(response.body)
            expect(json.dig("errors", "notify_error")).to eq("Simulated Notify Error")
          end

          it "process team only API key errors differently" do
            allow(ENV).to receive(:fetch).with("GOVUK_ENVIRONMENT", nil).and_return("integration")
            fake_response = double("response", code: 400, body: "Simulated team-only API key Error")
            specific_error = Notifications::Client::BadRequestError.new(fake_response)
            allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)
            allow(Rails.logger).to receive(:info)

            expect {
              post "/api/requests", params: valid_payload, as: :json
            }.to change(Request, :count).by(1)

            expect(response).to have_http_status(:bad_gateway)
            expect(Rails.logger).to have_received(:info).with(/GOV.UK Notify team/)
          end

          it "handles non API team key BadRequest exceptions" do
            allow(ENV).to receive(:fetch).with("GOVUK_ENVIRONMENT", nil).and_return("integration")
            fake_response = double("response", code: 400, body: "Simulated bad template error")
            specific_error = Notifications::Client::BadRequestError.new(fake_response)
            allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)
            allow(Rails.logger).to receive(:info)

            post "/api/requests", params: valid_payload, as: :json

            expect(Rails.logger).to have_received(:info).with(/Simulated bad template error/)
            json = JSON.parse(response.body)
            expect(json.dig("errors", "error_code")).to eq(400)
          end
        end
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

      it "does not create any new user collaborations records" do
        payload_missing_required_fields = { requester_name: "Alice" }

        expect {
          post "/api/requests", params: payload_missing_required_fields, as: :json
        }.not_to change(Collaboration, :count)
      end

      context "if current_content value is not a hash" do
        let(:dynamic_current_content) do
          {
            "id": { heading: "normal_field", body: "This should pass" },
            "id2": { heading: "bad_number_field", body: 123 },
          }
        end

        it "returns an error" do
          post "/api/requests", params: base_payload, as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Current content body in id2 must be a string")
        end
      end

      context "if current_content contains nested data" do
        let(:dynamic_current_content) do
          {
            "id": { heading: "normal_field", body: "This should pass" },
            "id2": { heading: "sneaky_nested_hash", body: { "naughty" => "This should fail" } },
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

      context "if current_content is not a hash" do
        let(:dynamic_current_content) { "not a hash" }

        it "returns an error" do
          post "/api/requests", params: base_payload, as: :json

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("current_content must be a hash")
        end
      end

      context "if previous_content is not a hash" do
        it "returns an error" do
          post "/api/requests", params: valid_payload.merge(previous_content: "not a hash"), as: :json

          expect(response).to have_http_status(:bad_request)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("previous_content must be a hash")
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

      context "if zendesk_number is not an number" do
        it "returns an error" do
          post "/api/requests", params: valid_payload.merge(zendesk_number: "not a number"), as: :json

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Zendesk number Zendesk number must be a number at least 7 digits long")
        end
      end
    end
  end

  describe "#resend_emails" do
    let(:existing_request) { create(:request) }

    context "valid request parameters" do
      before { expect(NotifyApiService).to receive(:resend_emails).and_return(true) }

      it "calls NotifyService#resend_emails" do
        post "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}/resend-emails", as: :json

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json).to include("id", "source_id", "source_app")
      end
    end

    context "invalid request parameters" do
      before { expect(NotifyApiService).not_to receive(:resend_emails) }
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
end
