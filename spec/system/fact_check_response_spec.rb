require "rails_helper"

RSpec.describe "FactCheckResponse", type: :system do
  before do
    allow(PublisherApiService).to receive(:post_fact_check_response)
                              .and_return(double(code: 200))
    allow(NotifyApiService).to receive(:send_email_to_recipient).and_return(double(code: 200))
  end

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

  describe "The response page" do
    context "when the running without an API failure" do
      it "allows the user to return to the comparison page with the back link" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_on(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))

        click_link("Back")
        expect(page).to have_text("This line will be changed")
      end

      it "allows the user to confirm the changes are correct" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

        choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_verification.heading"))
        expect(page).to have_text(I18n.t("fact_check_verification.confirm_changes"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_verification.change_link"))
        expect(page).to have_text(I18n.t("fact_check_verification.send_response"))
        expect(page).to have_text(I18n.t("fact_check_verification.send_response_warning"))
        expect(page).to have_button(I18n.t("fact_check_verification.confirm_button"))

        click_button(I18n.t("fact_check_verification.confirm_button"))
        expect(page).to have_current_path(confirm_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_submitted"))
        expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_description"))
        expect(page).to have_text(I18n.t("fact_check_submitted.sent_a_confirmation_email"))
        expect(page).to have_text(I18n.t("fact_check_submitted.what_happens_next"))
        expect(page).to have_text("We'll contact you on the Zendesk ticket (opens in new tab):")
        expect(page).to have_text(I18n.t("fact_check_submitted.when_changes"))
        expect(page).to have_text(I18n.t("fact_check_submitted.when_questions"))
        expect(page).to have_text(I18n.t("fact_check_submitted.what_do_you_think"))
        expect(page).to have_text(I18n.t("fact_check_submitted.thirty_sec"))
      end

      it "allows the user to click the change link without wiping the previous selection" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

        choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_verification.change_link"))

        click_link(I18n.t("fact_check_verification.change_link"))
        expect(page).to have_current_path("#{respond_path(source_app: request.source_app, source_id: request.source_id)}?back=true")

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_text(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_checked_field(I18n.t("fact_check_response.correct"), visible: :all)
      end

      it "allows the user to enter content into the factual error textbox and have it persist to confirmation" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

        choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
        page.fill_in "fact_check_details", with: "Fact check error detail test string"

        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_text(I18n.t("fact_check_verification.factual_errors"))
        expect(page).to have_text("Fact check error detail test string")
      end

      it "allows the user to click the change link without losing the detail contents for an incorrect response" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

        choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
        page.fill_in "fact_check_details", with: "Fact check error detail test string"

        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_text(I18n.t("fact_check_verification.factual_errors"))
        expect(page).to have_text("Fact check error detail test string")

        click_link(I18n.t("fact_check_verification.change_link"), match: :first)
        expect(page).to have_current_path("#{respond_path(source_app: request.source_app, source_id: request.source_id)}?back=true")

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_text(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_checked_field(I18n.t("fact_check_response.incorrect"), visible: :all)
        expect(page).to have_text("Fact check error detail test string")
      end
    end

    context "when submitting an incorrect response" do
      context "when the request does not have a Zendesk number" do
        let(:request) do
          FactoryBot.create(
            :request,
            :with_collaborator,
            collaborator: current_user,
            zendesk_number: nil,
            previous_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } },
            current_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } },
          )
        end
        it "shows the rejected confirmation page without a Zendesk link" do
          visit compare_path(source_app: request.source_app, source_id: request.source_id)
          click_link(I18n.t("fact_check_comparison.respond_to_button"))

          choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
          page.fill_in "fact_check_details", with: "Fact check error detail test string"

          click_button(I18n.t("fact_check_response.continue_button"))
          click_button(I18n.t("fact_check_verification.confirm_button"))

          expect(page).to have_current_path(
            confirm_response_path(source_app: request.source_app, source_id: request.source_id),
          )

          expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_submitted"))
          expect(page).to have_text(I18n.t("fact_check_submitted.rejected_contact_you"))
          expect(page).to have_text(I18n.t("fact_check_submitted.make_changes"))
          expect(page).to have_text(I18n.t("fact_check_submitted.send_new_content"))
          expect(page).to have_text(I18n.t("fact_check_submitted.rejected_contact_you"))
          expect(page).not_to have_link(I18n.t("fact_check_submitted.rejected_zendesk_link"))
        end
      end
      context "when the request has a Zendesk number" do
        it "shows the Zendesk link on the rejected confirmation page" do
          visit compare_path(source_app: request.source_app, source_id: request.source_id)
          click_link(I18n.t("fact_check_comparison.respond_to_button"))

          choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
          page.fill_in "fact_check_details", with: "Fact check error detail test string"

          click_button(I18n.t("fact_check_response.continue_button"))
          click_button(I18n.t("fact_check_verification.confirm_button"))

          expect(page).to have_current_path(
            confirm_response_path(source_app: request.source_app, source_id: request.source_id),
          )

          expect(page).to have_text("contact you on the")
          expect(page).to have_link("Zendesk ticket (opens in new tab)")
          expect(page).to have_text("if we have any questions")

          link = page.find_link(I18n.t("fact_check_submitted.rejected_zendesk_link"))

          expect(link[:href]).to eq(
            "https://govuk.zendesk.com/tickets/#{request.zendesk_number}",
          )
          expect(link[:target]).to eq("_blank")
        end
      end
    end

    context "when submitting without selecting a radio button" do
      it "shows a selection error" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.selection_error"))
      end
    end

    context "when submitting 'Incorrect' without entering body text" do
      it "shows a factual errors empty field error" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.factual_errors_empty_field"))
      end
    end

    context "when a response has already been submitted for the request" do
      let!(:response) { create(:response, request: request) }

      it "shows the already submitted page when trying to start the response flow" do
        visit respond_path(source_app: request.source_app, source_id: request.source_id)

        expect(page).to have_text(I18n.t("fact_check_already_submitted.heading"))
      end
    end

    context "when the API fails" do
      before do
        allow(PublisherApiService).to receive(:post_fact_check_response)
        .and_raise(GdsApi::HTTPErrorResponse.new(422, "", "forced test error"))
      end

      it "shows the user an error prompt suggesting to try submitting again" do
        visit compare_path(source_app: request.source_app, source_id: request.source_id)
        click_link(I18n.t("fact_check_comparison.respond_to_button"))
        expect(page).to have_current_path(respond_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_response.heading"))
        expect(page).to have_text(I18n.t("fact_check_response.form_heading"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_response.incorrect"))
        expect(page).to have_button(I18n.t("fact_check_response.continue_button"))

        choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
        click_button(I18n.t("fact_check_response.continue_button"))
        expect(page).to have_current_path(verify_response_path(source_app: request.source_app, source_id: request.source_id))

        expect(page).to have_text(I18n.t("fact_check_verification.heading"))
        expect(page).to have_text(I18n.t("fact_check_verification.confirm_changes"))
        expect(page).to have_text(I18n.t("fact_check_response.correct"))
        expect(page).to have_text(I18n.t("fact_check_verification.change_link"))
        expect(page).to have_text(I18n.t("fact_check_verification.send_response"))
        expect(page).to have_text(I18n.t("fact_check_verification.send_response_warning"))
        expect(page).to have_button(I18n.t("fact_check_verification.confirm_button"))

        click_button(I18n.t("fact_check_verification.confirm_button"))
        expect(page).to have_current_path(confirm_response_path(source_app: request.source_app, source_id: request.source_id))
        expect(page).to have_text(I18n.t("fact_check_verification.error_heading"))
        expect(page).to have_text(I18n.t("fact_check_verification.api_submission_error"))
      end
    end
  end
end
