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
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GOVUK_NOTIFY_NEW_FACT_CHECK_REQUEST_TEMPLATE_ID", nil).and_return("test-template-id")

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
