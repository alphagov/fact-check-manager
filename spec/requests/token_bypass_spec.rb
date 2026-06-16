require "rails_helper"

RSpec.describe "Token Bypass Access", type: :request do
  include AuthenticationHelper

  let(:request_record) { FactoryBot.create(:request) }

  describe "GET /requests/:source_app/:source_id/compare" do
    let(:url) { "/requests/#{request_record.source_app}/#{request_record.source_id}/compare" }

    context "with a valid token" do
      before { GDS::SSO.test_user = nil }

      it "bypasses authentication (does not call authenticate_user!)" do
        token = compare_preview_jwt_token(request_record)

        expect_any_instance_of(ApplicationController).not_to receive(:authenticate_user!)

        get url, params: { token: token }

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("Respond to fact check")
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

    context "when logged in as a GDS user who is not a collaborator or admin" do
      before { GDS::SSO.test_user = FactoryBot.create(:user) }

      it "prevents access with no token" do
        get url
        expect(response).to have_http_status(:forbidden)
      end

      it "allows access with a valid token" do
        token = compare_preview_jwt_token(request_record)

        get url, params: { token: token }
        expect(response).to have_http_status(:success)
      end

      it "prevents access with an invalid token" do
        token = "invalid-token"

        get url, params: { token: token }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when logged in as a GDS user who is a collaborator" do
      let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
      let(:request_record) do
        FactoryBot.create(
          :request,
          :with_collaborator,
          collaborator: current_user,
        )
      end

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

    context "when logged in as a GDS user who is an admin" do
      before do
        GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin govuk_admin])
      end

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

  describe "sign out link" do
    let(:url) { "/requests/#{request_record.source_app}/#{request_record.source_id}/compare" }

    context "when there is a current user" do
      before { GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin govuk_admin]) }

      it "renders the sign out link" do
        get url

        expect(response).to have_http_status(:success)
        expect(response.body).to include('href="/auth/gds/sign_out"')
      end
    end

    context "when there is no current user (token bypass)" do
      before { GDS::SSO.test_user = nil }

      it "does not render the sign out link" do
        token = compare_preview_jwt_token(request_record)

        get url, params: { token: token }

        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('href="/auth/gds/sign_out"')
      end
    end
  end
end
