require "rails_helper"

RSpec.describe "Token Bypass Access", type: :request do
  include TokenHelper

  let(:request_record) { FactoryBot.create(:request) }

  describe "GET /requests/:source_app/:source_id/preview" do
    let(:url) { "/requests/#{request_record.source_app}/#{request_record.source_id}/preview" }

    context "with a valid token" do
      before { GDS::SSO.test_user = nil }

      it "bypasses authentication (does not call authenticate_user!)" do
        token = compare_preview_jwt_token(request_record)

        expect_any_instance_of(ApplicationController).not_to receive(:authenticate_user!)

        get url, params: { token: token }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("shareable preview page")
      end
    end

    context "with an invalid token" do
      before { GDS::SSO.test_user = nil }

      it "attempts authentication (calls authenticate_user!)" do
        expect_any_instance_of(ApplicationController).to receive(:authenticate_user!) do |controller|
          controller.redirect_to("/auth/gds")
        end

        get url, params: { token: "invalid-token" }
        expect(response).to redirect_to("/auth/gds")
      end
    end

    context "with no token" do
      before { GDS::SSO.test_user = nil }

      it "attempts authentication (calls authenticate_user!)" do
        expect_any_instance_of(ApplicationController).to receive(:authenticate_user!) do |controller|
          controller.redirect_to("/auth/gds")
        end

        get url
        expect(response).to redirect_to("/auth/gds")
      end
    end

    context "when logged in as a GDS user" do
      it "allows access with no token" do
        get url
        expect(response).to have_http_status(:success)
      end

      it "allows access with a valid token" do
        token = compare_preview_jwt_token(request_record)

        get url, params: { token: token }
        expect(response).to have_http_status(:success)
      end

      it "allows access with an invalid token" do
        token = "invalid-token"

        get url, params: { token: token }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
