require "rails_helper"

RSpec.describe "Allowed URL parameters", type: :request do
  include AuthenticationHelper

  describe "GET /requests/:source_app/:source_id/compare" do
    let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
    let(:request) do
      FactoryBot.create(
        :request,
        :with_collaborator,
        collaborator: current_user,
        )
    end
    let(:url) { compare_path(source_app: request.source_app, source_id: request.source_id) }

    context "with GA4 params present" do
      it "allows expected param values through" do
        get url, params: {
          utm_source: "notify",
          utm_medium: "fishcake",
          utm_term: "sme",
          utm_content: "zendesk_ticket",
          utm_campaign: "fact_check"
        }
      end
    end
  end
end
