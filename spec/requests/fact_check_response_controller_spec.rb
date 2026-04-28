require "rails_helper"

RSpec.describe "FactCheckResponse", type: :request do
  context "signed in user who is a collaborator" do
    let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
    let(:request) do
      FactoryBot.create(
        :request,
        :with_collaborator,
        collaborator: current_user,
        previous_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } },
        current_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } },
      )
    end

    describe "GET /respond" do
      it "returns 404 when no request exists for the given source_app and source_id" do
        get respond_path(source_app: "invalid", source_id: "invalid")

        expect(response).to have_http_status(:not_found)
      end

      it "renders the response form" do
        get respond_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_response.heading"))
      end
    end

    describe "POST /verify-response" do
      it "returns 404 when no request exists for the given source_app and source_id" do
        post verify_response_path(source_app: "invalid", source_id: "invalid"),
             params: { fact_check_response: { accepted: "true" } }

        expect(response).to have_http_status(:not_found)
      end

      it "renders the verification page when accepted is provided and true" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_verification.heading"))
      end

      it "re-renders the response form with errors when accepted is blank" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_response.selection_error"))
      end

      it "re-renders the response form with errors when incorrect and body is blank" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "false", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_response.factual_errors_empty_field"))
      end

      it "does not require body when accepted is true" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_verification.heading"))
        expect(response.body).not_to include(I18n.t("fact_check_response.factual_errors_empty_field"))
      end
    end

    describe "POST /confirm-response" do
      before do
        allow(PublisherApiService).to receive(:post_fact_check_response)
          .and_return(double(code: 200))
      end

      it "returns 404 when no request exists for the given source_app and source_id" do
        post confirm_response_path(source_app: "invalid", source_id: "invalid"),
             params: { fact_check_response: { accepted: "true" } }

        expect(response).to have_http_status(:not_found)
      end

      it "creates a response and renders the submitted page on success" do
        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_submitted.fact_check_submitted"))
        expect(Response.count).to eq(1)
      end

      it "calls the PublisherApiService" do
        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(PublisherApiService).to have_received(:post_fact_check_response)
      end

      it "rolls back the response when the API fails" do
        allow(PublisherApiService).to receive(:post_fact_check_response)
          .and_raise(GdsApi::HTTPErrorResponse.new(422, "", "forced test error"))

        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_verification.api_submission_error"))
        expect(Response.count).to eq(0)
      end

      it "renders errors when a response has already been submitted for the request" do
        create(:response, request: request)

        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("has already been responded to")
        expect(Response.count).to eq(1)
      end
    end
  end

  context "signed in user who is an admin" do
    before do
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin govuk_admin])
    end
    let(:test_user) { FactoryBot.create(:user, email: "test@collab.test") }
    let(:request) do
      FactoryBot.create(:request, :with_collaborator, collaborator: test_user, previous_content: { "body" => "<div>Previous content</div>" },
                                                      current_content: { "body" => "<div>Current content</div>" })
    end

    describe "GET /respond" do
      it "renders the response form" do
        get respond_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_response.heading"))
      end
    end

    describe "POST /verify-response" do
      it "renders the verification page when accepted is provided and true" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_verification.heading"))
      end
    end

    describe "POST /confirm-response" do
      before do
        allow(PublisherApiService).to receive(:post_fact_check_response)
                                        .and_return(double(code: 200))
      end

      it "creates a response and renders the submitted page on success" do
        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_submitted.fact_check_submitted"))
        expect(Response.count).to eq(1)
      end
    end
  end

  context "signed in user who is not an admin or collaborator" do
    before do
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin])
    end
    let(:test_user) { FactoryBot.create(:user, email: "test@collab.test") }
    let(:request) do
      FactoryBot.create(:request, :with_collaborator, collaborator: test_user, previous_content: { "body" => "<div>Previous content</div>" },
                                                      current_content: { "body" => "<div>Current content</div>" })
    end

    describe "GET /respond" do
      it "redirects to the compare page" do
        get respond_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to redirect_to("/requests/#{request.source_app}/#{request.source_id}/compare")
      end
    end

    describe "POST /verify-response" do
      it "redirects to the compare page" do
        post verify_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true" } }

        expect(response).to redirect_to("/requests/#{request.source_app}/#{request.source_id}/compare")
      end
    end

    describe "POST /confirm-response" do
      before do
        allow(PublisherApiService).to receive(:post_fact_check_response)
                                        .and_return(double(code: 200))
      end

      it "redirects to the compare page" do
        post confirm_response_path(source_app: request.source_app, source_id: request.source_id),
             params: { fact_check_response: { accepted: "true", body: "" } }

        expect(response).to redirect_to("/requests/#{request.source_app}/#{request.source_id}/compare")
      end
    end
  end
end
