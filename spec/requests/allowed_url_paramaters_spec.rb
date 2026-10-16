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
      it "allows expected param values" do
        get url, params: {
          utm_source: "notify",
          utm_medium: "email",
          utm_term: "sme",
          utm_content: "zendesk_ticket",
          utm_campaign: "fact_check",
        }

        expect(response).to have_http_status(:success)
        expect(response.request.env["action_controller.instance"].send(:allowed_params))
          .to_s
          .include? '"utm_source" => "notify", "utm_medium" => "email", "utm_term" => "sme", "utm_content" => "zendesk_ticket", "utm_campaign" => "fact_check"'
      end

      it "prevents partial unexpected param values" do
        get url, params: {
          utm_source: "space",
          utm_medium: "email",
          utm_term: "sme",
          utm_content: "three_cats_in_a_trenchcoat",
          utm_campaign: "fact_check",
        }

        expect(response).to have_http_status(:success)

        allowed_params = response.request.env["action_controller.instance"].send(:allowed_params)

        expect(allowed_params)
          .to_s
          .include? '"utm_medium" => "email", "utm_term" => "sme", "utm_campaign" => "fact_check"'

        expect(allowed_params).not_to have_key("utm_source")
        expect(allowed_params).not_to have_key("utm_content")
      end

      it "prevents all unexpected param values with expected param keys" do
        get url, params: {
          utm_source: "space",
          utm_medium: "face",
          utm_term: "pace",
          utm_content: "three_cats_in_a_trenchcoat",
          utm_campaign: "running_away",
        }

        expect(response).to have_http_status(:success)

        allowed_params = response.request.env["action_controller.instance"].send(:allowed_params)
        expect(allowed_params).not_to have_key("utm_source")
        expect(allowed_params).not_to have_key("utm_medium")
        expect(allowed_params).not_to have_key("utm_term")
        expect(allowed_params).not_to have_key("utm_content")
        expect(allowed_params).not_to have_key("utm_campaign")
      end

      it "prevents unexpected param keys while allowing expected param values" do
        get url, params: {
          unauthorized_param: "why_is_this_here",
          utm_source: "notify",
          utm_medium: "email",
          unauthorized_param_2: "again_no",
          utm_term: "sme",
          utm_content: "zendesk_ticket",
          utm_campaign: "fact_check",
        }

        expect(response).to have_http_status(:success)

        allowed_params = response.request.env["action_controller.instance"].send(:allowed_params)
        expect(allowed_params)
          .to_s
          .include? '"utm_source" => "notify", "utm_medium" => "email", "utm_term" => "sme", "utm_content" => "zendesk_ticket", "utm_campaign" => "fact_check"'

        expect(allowed_params).not_to have_key("unauthorized_param")
        expect(allowed_params).not_to have_key("unathorized_param_2")
      end

      it "prevents all unexpected param keys" do
        get url, params: {
          unauthorized_param: "why_is_this_here",
          unauthorized_param_2: "again_no",
        }

        expect(response).to have_http_status(:success)

        allowed_params = response.request.env["action_controller.instance"].send(:allowed_params)
        expect(allowed_params).not_to have_key("unauthorized_param")
        expect(allowed_params).not_to have_key("unathorized_param_2")
      end
    end
  end
end
