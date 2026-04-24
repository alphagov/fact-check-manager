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
      @service.send_email_to_recipient(@user, @request, @personalisation_hash)

      expect(@notify_client_spy).to have_received(:send_email).with(
        hash_including(
          email_address: @user.email,
          reference: "#{@request.source_app}/#{@request.source_id}",
          personalisation: @personalisation_hash,
        ),
      )
    end
  end
end
