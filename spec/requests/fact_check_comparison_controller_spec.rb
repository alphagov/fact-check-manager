require "rails_helper"

RSpec.describe "FactCheckComparison", type: :request do
  context "signed in user who is a collaborator" do
    let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
    let(:request) do
      FactoryBot.create(:request, :with_collaborator, collaborator: current_user, source_title: "Example title",
                                                      deadline: Time.zone.now + 5.days,
                                                      previous_content: { "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" },
                                                      current_content: { "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" })
    end

    describe "GET /compare" do
      it "renders the expected unchanging assets" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_comparison.heading"))
        expect(response.body).to include(I18n.t("fact_check_comparison.respond_by"))
        expect(response.body).to include(I18n.t("fact_check_comparison.respond_to_button"))
        expect(response.body).to include(I18n.t("fact_check_comparison.preview_heading"))
        expect(response.body).to include(I18n.t("fact_check_comparison.preview_link"))
        expect(response.body).to include(I18n.t("fact_check_comparison.guidance_heading"))
        expect(response.body).to include(I18n.t("fact_check_comparison.guidance_deleted"))
        expect(response.body).to include(I18n.t("fact_check_comparison.guidance_added"))
        expect(response.body).to include(I18n.t("fact_check_comparison.guidance_link"))
      end

      it "includes a draft origin preview link with a JWT token" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response.body).to include("draft-origin.dev.gov.uk/#{request.draft_slug}")
        expect(response.body).to include("token=")
      end

      context "when draft origin fields are not present" do
        let(:request) do
          create(
            :request,
            draft_content_id: nil,
            draft_auth_bypass_id: nil,
            draft_slug: nil,
            previous_content: { "body" => "<div>Old content</div>" },
            current_content: { "body" => "<div>New content</div>" },
          )
        end

        it "does not render the preview section" do
          get compare_path(source_app: request.source_app, source_id: request.source_id)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include(I18n.t("fact_check_comparison.preview_heading"))
          expect(response.body).not_to include(I18n.t("fact_check_comparison.preview_link"))
        end
      end

      it "renders the diff with formatting" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        parsed = Nokogiri::HTML(response.body)

        expect(parsed.at_css("div.compare-editions")&.text).to include("This is the unchanged line.")

        expect(parsed.at_css("del")&.text).to include("This line will be changed")
        expect(parsed.at_css("del")&.text).not_to include("This is the unchanged line.")
        expect(parsed.at_css("del")&.text).not_to include("This line has changes")

        expect(parsed.at_css("ins")&.text).to include("This line has changes")
        expect(parsed.at_css("ins")&.text).not_to include("This is the unchanged line.")
        expect(parsed.at_css("ins")&.text).not_to include("This line will be changed")
      end

      it "returns 404 when no request exists for the given source_app and source_id" do
        get compare_path(source_app: "invalid", source_id: "invalid")

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "signed in user who is an admin" do
    before do
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin govuk_admin])
    end
    let(:test_user) { FactoryBot.create(:user, email: "test@collab.test") }
    let(:request) do
      FactoryBot.create(:request, :with_collaborator, collaborator: test_user, source_title: "Example title",
                                                      deadline: Time.zone.now + 5.days,
                                                      previous_content: { "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" },
                                                      current_content: { "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" })
    end

    describe "GET /compare" do
      it "renders the respond to fact check button" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("fact_check_comparison.respond_to_button"))
      end
    end
  end

  context "signed in user who is not admin or collaborator" do
    before do
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin])
    end
    let(:test_user) { FactoryBot.create(:user, email: "test@collab.test") }
    let(:request) do
      FactoryBot.create(:request, :with_collaborator, collaborator: test_user, source_title: "Example title",
                                                      deadline: Time.zone.now + 5.days,
                                                      previous_content: { "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" },
                                                      current_content: { "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" })
    end

    describe "GET /compare" do
      it "does not render the Response button" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(I18n.t("fact_check_comparison.respond_to_button"))
      end
    end
  end
end
