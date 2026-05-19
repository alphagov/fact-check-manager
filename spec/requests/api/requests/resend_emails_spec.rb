require "rails_helper"
require "notifications/client"

RSpec.describe "POST /api/requests/:source_app/:source_id/resend-emails", type: :request do
  before do
    @notify_client_spy = instance_spy(Notifications::Client)
    allow(Services).to receive(:notify_api).and_return(@notify_client_spy)
  end

  let(:user1) { create(:user, email: "recipient1@example.com") }
  let(:user2) { create(:user, email: "recipient2@example.com") }
  let(:existing_request) do
    request = create(:request)
    create(:collaboration, user: user1, request: request, role: "fact_checker")
    create(:collaboration, user: user2, request: request, role: "fact_checker")
    request
  end

  context "valid request parameters" do
    let(:make_request) do
      post "/api/requests/#{existing_request.source_app}/#{existing_request.source_id}/resend-emails", as: :json
    end

    it "returns ok with the request's identifiers" do
      allow(@notify_client_spy).to receive(:send_email)

      make_request

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("id", "source_id", "source_app")
    end

    context "successfully sends emails" do
      it "to each collaborator" do
        ClimateControl.modify(GOVUK_NOTIFY_NEW_FACT_CHECK_REQUEST_TEMPLATE_ID: "test-template-id") do
          allow(@notify_client_spy).to receive(:send_email)

          make_request

          expect(@notify_client_spy).to have_received(:send_email).with(hash_including(template_id: "test-template-id")).exactly(2).times
          expect(@notify_client_spy).to have_received(:send_email).with(hash_including(email_address: user1.email))
          expect(@notify_client_spy).to have_received(:send_email).with(hash_including(email_address: user2.email))
        end
      end
    end

    context "personalisation" do
      before { allow(@notify_client_spy).to receive(:send_email) }

      it "sets the title from the source_title" do
        existing_request.update!(source_title: "An interesting article")

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(title: "An interesting article"))).exactly(2).times
      end

      it "formats the deadline as a long date" do
        existing_request.update!(deadline: Time.zone.parse("2026-06-12T09:00:00Z"))

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(deadline: "Friday 12 June 2026"))).exactly(2).times
      end

      it "includes a tokenised compare link with the fact-check-manager URL prefix" do
        make_request

        expected_prefix = "#{Plek.external_url_for('fact-check-manager')}/requests/#{existing_request.source_app}/#{existing_request.source_id}/compare?token="

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(tokenised_link: start_with(expected_prefix)))).exactly(2).times
      end

      it "includes a non-tokenised compare link without a token" do
        make_request

        expected_link = "#{Plek.external_url_for('fact-check-manager')}/requests/#{existing_request.source_app}/#{existing_request.source_id}/compare"

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(non_tokenised_link: expected_link))).exactly(2).times
      end

      it "sets show_reason to yes and includes the reason when reason_for_change is present" do
        existing_request.update!(reason_for_change: "Important update")

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(show_reason: "yes", reason_for_change: "Important update"))).exactly(2).times
      end

      it "sets show_reason to no and reason_for_change to an empty string when reason_for_change is blank" do
        existing_request.update!(reason_for_change: "")

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(show_reason: "no", reason_for_change: ""))).exactly(2).times
      end

      it "sets show_zendesk_number to yes and includes the number when zendesk_number is present" do
        existing_request.update!(zendesk_number: 9_876_543)

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(show_zendesk_number: "yes", zendesk_number: 9_876_543))).exactly(2).times
      end

      it "sets show_zendesk_number to no and zendesk_number to an empty string when zendesk_number is blank" do
        existing_request.update!(zendesk_number: nil)

        make_request

        expect(@notify_client_spy).to have_received(:send_email)
          .with(hash_including(personalisation: hash_including(show_zendesk_number: "no", zendesk_number: ""))).exactly(2).times
      end
    end

    context "returns an error" do
      it "returns a bad gateway response for general error" do
        fake_response = double("response", code: 500, body: "Simulated Notify Error")
        specific_error = Notifications::Client::RequestError.new(fake_response)
        allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)

        make_request

        expect(response).to have_http_status(:bad_gateway)
        json = JSON.parse(response.body)
        expect(json.dig("errors", "notify_error")).to eq("Simulated Notify Error")
      end

      it "process team only API key errors differently" do
        ClimateControl.modify(GOVUK_ENVIRONMENT: "integration") do
          fake_response = double("response", code: 400, body: "Simulated team-only API key Error")
          specific_error = Notifications::Client::BadRequestError.new(fake_response)
          allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)
          allow(Rails.logger).to receive(:info)

          make_request

          expect(response).to have_http_status(:bad_gateway)
          expect(Rails.logger).to have_received(:info).with(/GOV.UK Notify team/)
        end
      end

      it "handles non API team key BadRequest exceptions" do
        ClimateControl.modify(GOVUK_ENVIRONMENT: "integration") do
          fake_response = double("response", code: 400, body: "Simulated bad template error")
          specific_error = Notifications::Client::BadRequestError.new(fake_response)
          allow(@notify_client_spy).to receive(:send_email).and_raise(specific_error)
          allow(Rails.logger).to receive(:info)

          make_request

          expect(Rails.logger).to have_received(:info).with(/Simulated bad template error/)
          json = JSON.parse(response.body)
          expect(json.dig("errors", "error_code")).to eq(400)
        end
      end
    end
  end

  context "invalid request parameters" do
    let(:make_request) do
      post "/api/requests/#{source_app}/#{source_id}/resend-emails", as: :json
    end

    before { expect(@notify_client_spy).not_to receive(:send_email) }

    context "invalid source_app and invalid source_id" do
      let(:source_app) { "invalid-source-app" }
      let(:source_id) { "invalid-source-id" }

      it "returns a 404" do
        make_request

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{source_id} not found for app #{source_app}",
        )
      end
    end

    context "valid source_app and invalid source_id" do
      let(:source_app) { existing_request.source_app }
      let(:source_id) { "invalid-source-id" }

      it "returns a 404" do
        make_request

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{source_id} not found for app #{source_app}",
        )
      end
    end

    context "invalid source_app and valid source_id" do
      let(:source_app) { "invalid-source-app" }
      let(:source_id) { existing_request.source_id }

      it "returns a 404" do
        make_request

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{source_id} not found for app #{source_app}",
        )
      end
    end

    context "source_app and source_id both valid, but invalid in combination" do
      let(:existing_request_whitehall) { create(:request, source_app: "whitehall") }
      let(:source_app) { existing_request_whitehall.source_app }
      let(:source_id) { existing_request.source_id }

      it "returns a 404" do
        make_request

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(
          "Request with ID #{source_id} not found for app #{source_app}",
        )
      end
    end
  end
end
