require "rails_helper"

RSpec.describe "FactCheckGA4", type: :system do
  let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }
  let(:request) do
    FactoryBot.create(
      :request,
      :with_collaborator,
      collaborator: current_user,
      source_title: "Example title",
      deadline: Time.zone.now + 5.days,
      previous_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } },
      current_content: { "test_id" => { "heading" => "Test Heading", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } },
    )
  end

  describe "Site wide navigation events" do
    it "pushes the correct values to the dataLayer on interactions with header links" do
      visit respond_path(source_app: request.source_app, source_id: request.source_id)
      disable_links

      find("header").click_link("Fact Check Manager")
      click_link("Sign out")

      event_data = get_event_data

      expect(event_data[0]["event_name"]).to eq("navigation")
      expect(event_data[0]["type"]).to eq("header")
      expect(event_data[0]["url"]).to eq("/")
      expect(event_data[0]["text"]).to eq("Fact Check Manager")
      expect(event_data[0]["link_domain"]).to eq(current_host)
      expect(event_data[0]["index"]["index_link"]).to eq("1")
      expect(event_data[0]["index"]["index_section"]).to eq("1")
      expect(event_data[0]["index"]["index_section_count"]).to eq("2")
      expect(event_data[0]["index_total"]).to eq("2")
      expect(event_data[0]["method"]).to eq("primary click")
      expect(event_data[0]["external"]).to eq("false")
      expect(event_data[0]["section"]).to eq("Fact Check Manager")

      expect(event_data[1]["event_name"]).to eq("navigation")
      expect(event_data[1]["type"]).to eq("header")
      expect(event_data[1]["url"]).to eq("/auth/gds/sign_out")
      expect(event_data[1]["text"]).to eq("Sign out")
      expect(event_data[1]["link_domain"]).to eq(current_host)
      expect(event_data[1]["index"]["index_link"]).to eq("2")
      expect(event_data[1]["index"]["index_section"]).to eq("2")
      expect(event_data[1]["index"]["index_section_count"]).to eq("2")
      expect(event_data[1]["index_total"]).to eq("2")
      expect(event_data[1]["method"]).to eq("primary click")
      expect(event_data[1]["external"]).to eq("false")
      expect(event_data[1]["section"]).to eq("Sign out")
    end

    it "pushes the correct values to the dataLayer on interactions with footer links" do
      visit respond_path(source_app: request.source_app, source_id: request.source_id)
      disable_links

      click_link("Report a technical fault to GDS")
      click_link("Give feedback on Fact Check Manager")
      click_link("Check if publishing apps are working or if there’s any maintenance planned")
      click_link("Privacy notice")
      click_link("Open Government Licence v3.0")
      click_link("© Crown copyright")

      event_data = get_event_data

      expect(event_data[0]["event_name"]).to eq("navigation")
      expect(event_data[0]["type"]).to eq("footer")
      expect(event_data[0]["url"]).to end_with("/technical_fault_report/new")
      expect(event_data[0]["text"]).to eq("Report a technical fault to GDS")
      expect(event_data[0]["link_domain"]).to eq("http://support.dev.gov.uk")
      expect(event_data[0]["index"]["index_link"]).to eq("1")
      expect(event_data[0]["index"]["index_section"]).to eq("1")
      expect(event_data[0]["index"]["index_section_count"]).to eq("3")
      expect(event_data[0]["index_total"]).to eq("4")
      expect(event_data[0]["method"]).to eq("primary click")
      expect(event_data[0]["external"]).to eq("true")
      expect(event_data[0]["section"]).to eq("Support and feedback")

      expect(event_data[1]["event_name"]).to eq("navigation")
      expect(event_data[1]["type"]).to eq("footer")
      expect(event_data[1]["url"]).to end_with("/done/fact-check-manager")
      expect(event_data[1]["text"]).to eq("Give feedback on Fact Check Manager")
      expect(event_data[1]["link_domain"]).to eq("http://www.dev.gov.uk")
      expect(event_data[1]["index"]["index_link"]).to eq("2")
      expect(event_data[1]["index"]["index_section"]).to eq("1")
      expect(event_data[1]["index"]["index_section_count"]).to eq("3")
      expect(event_data[1]["index_total"]).to eq("4")
      expect(event_data[1]["method"]).to eq("primary click")
      expect(event_data[1]["external"]).to eq("true")
      expect(event_data[1]["section"]).to eq("Support and feedback")

      expect(event_data[2]["event_name"]).to eq("navigation")
      expect(event_data[2]["type"]).to eq("footer")
      expect(event_data[2]["url"]).to eq("https://status.publishing.service.gov.uk/")
      expect(event_data[2]["text"]).to eq("Check if publishing apps are working or if there’s any maintenance planned")
      expect(event_data[2]["link_domain"]).to eq("https://status.publishing.service.gov.uk")
      expect(event_data[2]["index"]["index_link"]).to eq("3")
      expect(event_data[2]["index"]["index_section"]).to eq("1")
      expect(event_data[2]["index"]["index_section_count"]).to eq("3")
      expect(event_data[2]["index_total"]).to eq("4")
      expect(event_data[2]["method"]).to eq("primary click")
      expect(event_data[2]["external"]).to eq("true")
      expect(event_data[2]["section"]).to eq("Support and feedback")

      expect(event_data[3]["event_name"]).to eq("navigation")
      expect(event_data[3]["type"]).to eq("footer")
      expect(event_data[3]["url"]).to end_with("/privacy-notice")
      expect(event_data[3]["text"]).to eq("Privacy notice")
      expect(event_data[3]["link_domain"]).to eq("http://signon.dev.gov.uk")
      expect(event_data[3]["index"]["index_link"]).to eq("4")
      expect(event_data[3]["index"]["index_section"]).to eq("1")
      expect(event_data[3]["index"]["index_section_count"]).to eq("3")
      expect(event_data[3]["index_total"]).to eq("4")
      expect(event_data[3]["method"]).to eq("primary click")
      expect(event_data[3]["external"]).to eq("true")
      expect(event_data[3]["section"]).to eq("Support and feedback")

      expect(event_data[4]["event_name"]).to eq("navigation")
      expect(event_data[4]["type"]).to eq("footer")
      expect(event_data[4]["url"]).to end_with("/doc/open-government-licence/version/3/")
      expect(event_data[4]["text"]).to eq("Open Government Licence v3.0")
      expect(event_data[4]["link_domain"]).to eq("https://www.nationalarchives.gov.uk")
      expect(event_data[4]["index"]["index_link"]).to eq("1")
      expect(event_data[4]["index"]["index_section"]).to eq("2")
      expect(event_data[4]["index"]["index_section_count"]).to eq("3")
      expect(event_data[4]["index_total"]).to eq("1")
      expect(event_data[4]["method"]).to eq("primary click")
      expect(event_data[4]["external"]).to eq("true")
      expect(event_data[4]["section"]).to eq("Licence")

      expect(event_data[5]["event_name"]).to eq("navigation")
      expect(event_data[5]["type"]).to eq("footer")
      expect(event_data[5]["url"]).to end_with("/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/")
      expect(event_data[5]["text"]).to eq("© Crown copyright")
      expect(event_data[5]["link_domain"]).to eq("https://www.nationalarchives.gov.uk")
      expect(event_data[5]["index"]["index_link"]).to eq("1")
      expect(event_data[5]["index"]["index_section"]).to eq("3")
      expect(event_data[5]["index"]["index_section_count"]).to eq("3")
      expect(event_data[5]["index_total"]).to eq("1")
      expect(event_data[5]["method"]).to eq("primary click")
      expect(event_data[5]["external"]).to eq("true")
      expect(event_data[5]["section"]).to eq("Copyright")
    end
  end

  describe "Fact check the changes page" do
    it "pushes the correct values to the dataLayer on load" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)

      page_view = get_page_view_data

      expect(page_view["user_created_at"]).to eq(current_user.created_at.to_date.to_s)
      expect(page_view["user_organisation_name"]).to eq(current_user.organisation_slug)
      expect(page_view["user_id"]).to eq(current_user.anonymous_user_id)
      expect(page_view["content_id"]).to eq(request.source_id)
    end

    it "pushes the correct values to the dataLayer when the user interacts with page elements" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)
      disable_links

      click_link("Respond to fact check")
      click_link("Preview the draft page (opens in new tab)")
      click_link("Fact checking guidance (opens in new tab)")

      event_data = get_event_data

      expect(event_data[0]["event_name"]).to eq("navigation")
      expect(event_data[0]["link_domain"]).to eq(current_host)
      expect(event_data[0]["method"]).to eq("primary click")
      expect(event_data[0]["external"]).to eq("false")
      expect(event_data[0]["text"]).to eq("Respond to fact check")
      expect(event_data[0]["type"]).to eq("generic_link")
      expect(event_data[0]["url"]).to eq("/requests/publisher/#{request.source_id}/respond")

      expect(event_data[1]["event_name"]).to eq("navigation")
      expect(event_data[1]["link_domain"]).to start_with("http://draft-origin")
      expect(event_data[1]["method"]).to eq("primary click")
      expect(event_data[1]["external"]).to eq("true")
      expect(event_data[1]["text"]).to eq("Preview the draft page (opens in new tab)")
      expect(event_data[1]["type"]).to eq("generic_link")
      expect(event_data[1]["url"]).to include(request.draft_slug.to_s)

      expect(event_data[2]["event_name"]).to eq("navigation")
      expect(event_data[2]["link_domain"]).to eq("https://gov.uk")
      expect(event_data[2]["method"]).to eq("primary click")
      expect(event_data[2]["external"]).to eq("true")
      expect(event_data[2]["text"]).to eq("Fact checking guidance (opens in new tab)")
      expect(event_data[2]["type"]).to eq("generic_link")
      expect(event_data[2]["url"]).to eq("https://gov.uk/government/publications/how-content-requests-from-government-get-published/fact-checking-content-on-govuk")
    end
  end

  describe "Confirm the changes are factually correct page" do
    it "pushes the correct values to the dataLayer on load" do
      visit respond_path(source_app: request.source_app, source_id: request.source_id)

      page_view = get_page_view_data

      expect(page_view["user_created_at"]).to eq(current_user.created_at.to_date.to_s)
      expect(page_view["user_organisation_name"]).to eq(current_user.organisation_slug)
      expect(page_view["user_id"]).to eq(current_user.anonymous_user_id)
      expect(page_view["content_id"]).to eq(request.source_id)
    end

    it "pushes the correct values to the dataLayer when the user interacts with page elements" do
      visit respond_path(source_app: request.source_app, source_id: request.source_id)
      disable_links
      disable_form_submit

      choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
      choose(I18n.t("fact_check_response.incorrect"), allow_label_click: true)
      page.fill_in(I18n.t("fact_check_response.factual_errors"), with: "It is wrong")
      click_link("Back")
      click_button(I18n.t("fact_check_response.continue_button"))

      event_data = get_event_data

      expect(event_data[0]["action"]).to eq("select")
      expect(event_data[0]["event_name"]).to eq("select_content")
      expect(event_data[0]["index"]["index_section"]).to eq("1")
      expect(event_data[0]["index"]["index_section_count"]).to eq("1")
      expect(event_data[0]["section"]).to eq("Are the changes factually correct?")
      expect(event_data[0]["text"]).to eq("Yes, they're correct")

      expect(event_data[1]["action"]).to eq("select")
      expect(event_data[1]["event_name"]).to eq("select_content")
      expect(event_data[1]["index"]["index_section"]).to eq("1")
      expect(event_data[1]["index"]["index_section_count"]).to eq("1")
      expect(event_data[1]["section"]).to eq("Are the changes factually correct?")
      expect(event_data[1]["text"]).to eq("No, there's an error")

      expect(event_data[2]["action"]).to eq("select")
      expect(event_data[2]["event_name"]).to eq("select_content")
      expect(event_data[2]["index"]["index_section"]).to eq("1")
      expect(event_data[2]["index"]["index_section_count"]).to eq("1")
      expect(event_data[2]["section"]).to eq("What are the factual errors?")
      expect(event_data[2]["text"]).to eq("11")

      expect(event_data[3]["event_name"]).to eq("navigation")
      expect(event_data[3]["link_domain"]).to eq(current_host)
      expect(event_data[3]["method"]).to eq("primary click")
      expect(event_data[3]["external"]).to eq("false")
      expect(event_data[3]["text"]).to eq("Back")
      expect(event_data[3]["type"]).to eq("back")
      expect(event_data[3]["url"]).to eq(compare_path(source_app: request.source_app, source_id: request.source_id))

      expect(event_data[4]["action"]).to eq("continue")
      expect(event_data[4]["event_name"]).to eq("form_response")
      expect(event_data[4]["section"]).to eq("Confirm the changes are factually correct")
      expect(event_data[4]["text"]).to eq("{\"Are the changes factually correct?\":\"No, there's an error\",\"What are the factual errors?\":\"11\"}")
      expect(event_data[4]["type"]).to eq("new")
    end
  end

  describe "Fact check submitted page" do
    it "pushes the correct values to the dataLayer on load" do
      visit compare_path(source_app: request.source_app, source_id: request.source_id)
      click_link(I18n.t("fact_check_comparison.respond_to_button"))

      page_view = get_page_view_data

      expect(page_view["user_created_at"]).to eq(current_user.created_at.to_date.to_s)
      expect(page_view["user_organisation_name"]).to eq(current_user.organisation_slug)
      expect(page_view["user_id"]).to eq(current_user.anonymous_user_id)
      expect(page_view["content_id"]).to eq(request.source_id)
    end

    it "pushes the correct values to the dataLayer when the user interacts with page elements" do
      # There must be a better way to get to the page
      visit compare_path(source_app: request.source_app, source_id: request.source_id)
      click_link(I18n.t("fact_check_comparison.respond_to_button"))
      choose(I18n.t("fact_check_response.correct"), allow_label_click: true)
      click_button(I18n.t("fact_check_response.continue_button"))
      click_button(I18n.t("fact_check_verification.confirm_button"))

      # For sanity only
      expect(page).to have_text(I18n.t("fact_check_submitted.fact_check_submitted"))

      disable_links

      click_link("Zendesk ticket (opens in new tab)")
      click_link("What do you think of this service?")

      event_data = get_event_data

      puts "++event_data++"
      puts event_data
      puts "++++"

      expect(event_data[0]["event_name"]).to eq("navigation")
      expect(event_data[0]["link_domain"]).to eq("https://govuk.zendesk.com")
      expect(event_data[0]["method"]).to eq("primary click")
      expect(event_data[0]["external"]).to eq("true")
      expect(event_data[0]["text"]).to eq("Zendesk ticket (opens in new tab)")
      expect(event_data[0]["type"]).to eq("generic_link")
      expect(event_data[0]["url"]).to end_with("/tickets/1234567")

      expect(event_data[1]["event_name"]).to eq("navigation")
      expect(event_data[1]["link_domain"]).to eq("https://www.gov.uk")
      expect(event_data[1]["method"]).to eq("primary click")
      expect(event_data[1]["external"]).to eq("true")
      expect(event_data[1]["text"]).to eq("What do you think of this service?")
      expect(event_data[1]["type"]).to eq("generic_link")
      expect(event_data[1]["url"]).to end_with("/done/fact-check-manager")
    end
  end

  def disable_links
    execute_script("document.addEventListener('click',function(e){if(e.target.closest('a'))(e.preventDefault())})")
  end

  def disable_form_submit
    execute_script("document.querySelector('form').addEventListener('submit',function(e){e.preventDefault()})")
  end

  def get_event_data
    event_data = []
    data_layer_items = evaluate_script("window.dataLayer")

    data_layer_items.each do |item|
      if item["event_data"]
        event_data << item["event_data"]
      end
    end

    event_data
  end

  def get_page_view_data
    page_view = {}
    data_layer_items = evaluate_script("window.dataLayer")

    data_layer_items.each do |item|
      if item["page_view"]
        page_view = item["page_view"]
      end
    end

    page_view
  end
end
