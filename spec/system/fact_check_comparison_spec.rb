require "rails_helper"

RSpec.describe "FactCheckComparison", type: :system do
  let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
  let(:previous_content) { { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><h2>This line will be changed</h2>" } } }
  let(:previous_markdown) { { "test_id" => { "heading" => "Test Heading", "body" => "This is the unchanged line. # This line will be changed" } } }
  let(:request) do
    FactoryBot.create(
      :request,
      :with_collaborator,
      collaborator: current_user,
      source_title: "Example title",
      deadline: Time.zone.now + 5.days,
      previous_content:,
      current_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><h2>This line has changes</h2" } },
      current_markdown: { "test_id" => { "heading" => "Test Heading", "body" => "This is the unchanged line. # This line has changes" } },
      previous_markdown:,
    )
  end

  describe "The comparison page" do
    it "displays the article title, deadline and both view tabs" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text(request.source_title)
      expect(page).to have_text(request.formatted_deadline)
      expect(page).to have_css("a", id: "tab_formatted-view", text: "Formatted view")
      expect(page).to have_css("a", id: "tab_markdown-view", text: "Markdown view")
    end

    it "displays deleted and added content in the HTML diff" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text("This is the unchanged line.")
      expect(page).to have_css(".del", text: "This line will be changed")
      expect(page).to have_css(".ins", text: "This line has changes")
      expect(page).not_to have_css(".del", text: "# This line will be changed")
      expect(page).not_to have_css(".ins", text: "# This line has changes")
    end

    it "displays deleted and added content in the govspeak diff" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id, anchor: "markdown-view")

      expect(page).to have_text("This is the unchanged line.")
      expect(page).to have_css(".del", text: "# This line will be changed")
      expect(page).to have_css(".ins", text: "# This line has changes")
      expect(page).not_to have_css(".del", text: "line. This line will be changed")
      expect(page).not_to have_css(".ins", text: "line. This line has changes")
    end

    it "has a link to respond to the fact check" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      click_link(I18n.t("fact_check_comparison.respond_to_button"))

      expect(page).to have_text(I18n.t("fact_check_response.heading"))
    end

    it "displays the draft origin preview link" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text(I18n.t("fact_check_comparison.preview_heading"))
      expect(page).to have_link(I18n.t("fact_check_comparison.preview_link"))
      expect(page).to have_text(I18n.t("fact_check_comparison.preview_link_expiry"))
    end

    it "displays the guidance sidebar" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text(I18n.t("fact_check_comparison.guidance_heading"))
      expect(page).to have_text(I18n.t("fact_check_comparison.guidance_deleted"))
      expect(page).to have_text(I18n.t("fact_check_comparison.guidance_added"))
      expect(page).to have_link(I18n.t("fact_check_comparison.guidance_link"))
    end

    context "when the request has no previous content" do
      let(:previous_content) { {} }

      it "displays the guidance sidebar with the first edition text" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(page).to have_text(I18n.t("fact_check_comparison.guidance_heading"))
        expect(page).to have_text(I18n.t("fact_check_comparison.guidance_first_edition"))
        expect(page).to have_link(I18n.t("fact_check_comparison.guidance_link"))
      end
    end

    context "when no draft preview link can be generated" do
      before do
        allow_any_instance_of(AuthenticationHelper).to receive(:draft_origin_preview_url).and_return(nil)
      end

      it "does not render the preview section or link" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(page).not_to have_text(I18n.t("fact_check_comparison.preview_heading"))
        expect(page).not_to have_link(I18n.t("fact_check_comparison.preview_link"))
        expect(page).not_to have_text(I18n.t("fact_check_comparison.preview_link_expiry"))
      end
    end
  end
end
