require "rails_helper"

RSpec.describe "FactCheckResponse", type: :system do
  before do
    create(:user)
  end

  describe "GET /respond" do
    it "allows the user to confirm the changes are correct" do
      visit respond_path

      expect(page).to have_text(I18n.t("fact_check_response.heading"))
      expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
      expect(page).to have_text(I18n.t("fact_check_response.correct"))
      expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
      expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

      choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
      click_button(I18n.t("fact_check_response.continue_button"))

      expect(page).to have_text(I18n.t("fact_check_verification.heading"))
      expect(page).to have_text(I18n.t("fact_check_verification.confirm_changes"))
      expect(page).to have_text(I18n.t("fact_check_response.correct"))
      expect(page).to have_text(I18n.t("fact_check_verification.change_link"))
      expect(page).to have_text(I18n.t("fact_check_verification.send_response"))
      expect(page).to have_text(I18n.t("fact_check_verification.send_response_warning"))
      expect(page).to have_button(I18n.t("fact_check_verification.confirm_button"))

      click_button(I18n.t("fact_check_verification.confirm_button"))

      expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_submitted"))
      expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_description"))
      expect(page).to have_text(I18n.t("fact_check_submitted.thank_you"))
      expect(page).to have_text(I18n.t("fact_check_submitted.what_happens_next"))
      expect(page).to have_text(I18n.t("fact_check_submitted.contact_you"))
      expect(page).to have_text(I18n.t("fact_check_submitted.when_changes"))
      expect(page).to have_text(I18n.t("fact_check_submitted.when_questions"))
      expect(page).to have_text(I18n.t("fact_check_submitted.what_do_you_think"))
      expect(page).to have_text(I18n.t("fact_check_submitted.thirty_sec"))
    end

    it "allows the user to click the change link without wiping the previous selection" do
      visit respond_path

      expect(page).to have_text(I18n.t("fact_check_response.heading"))
      expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
      expect(page).to have_text(I18n.t("fact_check_response.correct"))
      expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
      expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

      choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
      click_button(I18n.t("fact_check_response.continue_button"))

      expect(page).to have_text(I18n.t("fact_check_response.correct"))
      expect(page).to have_text(I18n.t("fact_check_verification.change_link"))

      click_link(I18n.t("fact_check_verification.change_link"))

      expect(page).to have_text(I18n.t("fact_check_response.heading"))
      expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
      expect(page).to have_text(I18n.t("fact_check_response.correct"))
      expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
      expect(page).to have_text(I18n.t("fact_check_response.continue_button"))
      expect(page).to have_checked_field(I18n.t("fact_check_response.correct"), visible: :all)
    end
  end
end
