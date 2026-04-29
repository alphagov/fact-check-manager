require "rails_helper"

RSpec.describe "FactCheckComparison", type: :system do
  let(:request) do
    create(
      :request,
      source_title: "Example title",
      deadline: Time.zone.now + 5.days,
      previous_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } },
      current_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } },
    )
  end

  describe "The comparison page" do
    it "displays the article title and deadline" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text(request.source_title)
      expect(page).to have_text(request.deadline.to_date)
    end

    it "displays deleted and added content in the diff" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      expect(page).to have_text("This is the unchanged line.")
      expect(page).to have_css("del", text: "This line will be changed")
      expect(page).to have_css("ins", text: "This line has changes")
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

    context "when no draft preview link can be generated" do
      before do
        allow_any_instance_of(TokenHelper).to receive(:draft_origin_preview_url).and_return(nil)
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
