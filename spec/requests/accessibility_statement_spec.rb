require "rails_helper"

RSpec.describe "Accessibility statement", type: :request do
  include AuthenticationHelper

  let(:request_record) { FactoryBot.create(:request) }
  let(:source_params) { { source_app: request_record.source_app, source_id: request_record.source_id } }

  describe "GET /accessibility-statement" do
    context "when there is a current user" do
      it "renders the accessibility statement" do
        get accessibility_statement_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Accessibility statement for Fact Check Manager")
      end
    end

    context "when there is no current user" do
      before { GDS::SSO.test_user = nil }

      it "bypasses authentication with a valid token" do
        token = compare_preview_jwt_token(request_record)

        expect_any_instance_of(ApplicationController).not_to receive(:authenticate_user!)

        get accessibility_statement_path, params: source_params.merge(token: token)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Accessibility statement for Fact Check Manager")
      end

      it "requires authentication with an invalid token" do
        expect_any_instance_of(ApplicationController).to receive(:authenticate_user!) do |controller|
          controller.redirect_to("/auth/gds")
        end

        get accessibility_statement_path, params: source_params.merge(token: "invalid-token")
        expect(response).to redirect_to("/auth/gds")
      end

      it "requires authentication with a token for a different request" do
        token = compare_preview_jwt_token(FactoryBot.create(:request))

        expect_any_instance_of(ApplicationController).to receive(:authenticate_user!) do |controller|
          controller.redirect_to("/auth/gds")
        end

        get accessibility_statement_path, params: source_params.merge(token: token)
        expect(response).to redirect_to("/auth/gds")
      end

      it "requires authentication with no token" do
        expect_any_instance_of(ApplicationController).to receive(:authenticate_user!) do |controller|
          controller.redirect_to("/auth/gds")
        end

        get accessibility_statement_path
        expect(response).to redirect_to("/auth/gds")
      end
    end
  end

  describe "footer link" do
    let(:url) { "/requests/#{request_record.source_app}/#{request_record.source_id}/compare" }

    context "when there is a current user" do
      it "links to the accessibility statement without a token" do
        get url

        expect(response.body).to include('href="/accessibility-statement"')
      end
    end

    context "when there is no current user (token bypass)" do
      before { GDS::SSO.test_user = nil }

      it "links to the accessibility statement with the token" do
        token = compare_preview_jwt_token(request_record)

        get url, params: { token: token }

        link = URI.parse(Nokogiri::HTML(response.body).at_css("a:contains('Accessibility statement')")["href"])
        expect(link.path).to eq(accessibility_statement_path)
        expect(Rack::Utils.parse_query(link.query)).to eq(source_params.merge(token: token).stringify_keys)
      end
    end
  end
end
