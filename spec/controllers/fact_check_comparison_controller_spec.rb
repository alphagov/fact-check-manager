require "rails_helper"

RSpec.describe "FactCheckComparison", type: :request do
  before do
    create(:user)

    allow_any_instance_of(FactCheckComparisonController).to receive(:previous_content)
      .and_return("<div>This is the unchanged line.</div><div>This line will be changed</div>")

    allow_any_instance_of(FactCheckComparisonController).to receive(:current_content)
      .and_return("<div>This is the unchanged line.</div><div>This line has changes</div>")
  end

  describe "GET /compare" do
    it "renders the expected unchanging assets" do
      get compare_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("fact_check_comparison.fact_check_heading"))
      expect(response.body).to include(I18n.t("fact_check_comparison.respond_by"))
      expect(response.body).to include(I18n.t("fact_check_comparison.respond_to_button"))
      expect(response.body).to include(I18n.t("fact_check_comparison.preview_heading"))
      expect(response.body).to include(I18n.t("fact_check_comparison.preview_link"))
      expect(response.body).to include(I18n.t("fact_check_comparison.guidance_heading"))
      expect(response.body).to include(I18n.t("fact_check_comparison.guidance_deleted"))
      expect(response.body).to include(I18n.t("fact_check_comparison.guidance_added"))
      expect(response.body).to include(I18n.t("fact_check_comparison.guidance_link"))
    end

    it "renders the diff with formatting" do
      get compare_path

      parsed = Nokogiri::HTML(response.body)

      expect(parsed.at_css("div.compare-editions")&.text).to include("This is the unchanged line.")

      expect(parsed.at_css("del")&.text).to include("This line will be changed")
      expect(parsed.at_css("del")&.text).not_to include("This is the unchanged line.")
      expect(parsed.at_css("del")&.text).not_to include("This line has changes")

      expect(parsed.at_css("ins")&.text).to include("This line has changes")
      expect(parsed.at_css("ins")&.text).not_to include("This is the unchanged line.")
      expect(parsed.at_css("ins")&.text).not_to include("This line will be changed")
    end
  end
end
