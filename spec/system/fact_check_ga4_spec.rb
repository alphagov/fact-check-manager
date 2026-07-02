require "rails_helper"

# Much of this can probably be removed for this test
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

  describe "Confirm the changes are factually correct page" do
    it "pushes the correct values to the dataLayer on load" do
      visit respond_path(source_app: request.source_app, source_id: request.source_id)

      data_layer_items = get_data_layer_items
      page_view = {}

      data_layer_items.each do |item|
        if item["page_view"]
          page_view = item["page_view"]
        end
      end

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

      data_layer_items = get_data_layer_items
      event_data = []

      data_layer_items.each do |item|
        if item["event_data"]
          event_data << item["event_data"]
        end
      end

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

  def disable_links
    execute_script("document.addEventListener('click',function(e){if(e.target.href)(e.preventDefault())})")
  end

  def disable_form_submit
    execute_script("document.querySelector('form').addEventListener('submit',function(e){e.preventDefault()})")
  end

  def get_data_layer_items
    evaluate_script("window.dataLayer")
  end
end
