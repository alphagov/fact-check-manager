require "rails_helper"
require "notifications/client"

RSpec.describe NotifyApiService do
  before do
    @request = build(:request)
    @user = create(:user, name: "Douglas Adams")
    @service = described_class
    @personalisation_hash = { greeting: "Hola, Mundo!!" }
    @notify_client_spy = instance_spy(Notifications::Client)
    allow(Services).to receive(:notify_api).and_return(@notify_client_spy)
  end

  context "sending individual emails" do
    it "sends the provided data to Notify" do
      @service.send_email_to_recipient(@user, @request, NotifyApiService::NOTIFY_TEST_TEMPLATE_ID, @personalisation_hash)

      expect(@notify_client_spy).to have_received(:send_email).with(
        hash_including(
          email_address: @user.email,
          template_id: NotifyApiService::NOTIFY_TEST_TEMPLATE_ID,
          reference: "#{@request.source_app}/#{@request.source_id}",
          personalisation: @personalisation_hash,
        ),
      )
    end
  end

  context ".send_new_fact_check_request_email" do
    it "sends with the template_id from GOVUK_NOTIFY_NEW_FACT_CHECK_REQUEST_TEMPLATE_ID" do
      ClimateControl.modify(GOVUK_NOTIFY_NEW_FACT_CHECK_REQUEST_TEMPLATE_ID: "test-template-id") do
        @service.send_new_fact_check_request_email(@user, @request, @personalisation_hash)

        expect(@notify_client_spy).to have_received(:send_email).with(
          hash_including(
            email_address: @user.email,
            template_id: "test-template-id",
            reference: "#{@request.source_app}/#{@request.source_id}",
            personalisation: @personalisation_hash,
          ),
        )
      end
    end
  end

  context ".send_response_accepted_email" do
    it "sends the correct data to Notify for a fact check accepted response" do
      ClimateControl.modify(GOVUK_NOTIFY_RESPONSE_ACCEPTED_TEMPLATE_ID: "test-response-template-id") do
        response = build(:response, request: @request)
        personalisation_hash = { content_title: @request.source_title, responder_name: response.user.name }
        @service.send_response_accepted_email(response, personalisation_hash)

        expect(@notify_client_spy).to have_received(:send_email).with(
          hash_including(
            email_address: response.user.email,
            template_id: "test-response-template-id",
            reference: "#{@request.source_app}/#{@request.source_id}",
            personalisation: personalisation_hash,
          ),
        )
      end
    end
  end
end
