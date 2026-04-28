require "rails_helper"
require "helpers/formatted_diff_helpers"

RSpec.describe "FactCheckComparison", type: :request do
  include FormattedDiffHelpers

  describe "GET /compare" do
    let(:current_user) { GDS::SSO.test_user = FactoryBot.create(:user) }

    let(:request) do
      FactoryBot.create(
        :request,
        :with_collaborator,
        collaborator: current_user,
        source_title: "Example title",
        deadline: Time.zone.now + 5.days,
        previous_content: previous_content,
        current_content: current_content,
      )
    end

    context "signed in user who is an admin" do
      before do
        GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin govuk_admin])
      end
      let(:test_user) { FactoryBot.create(:user, email: "test@collab.test") }
      let(:request) do
        FactoryBot.create(
          :request,
          :with_collaborator,
          collaborator: test_user,
          source_title: "Example title",
          deadline: Time.zone.now + 5.days,
          previous_content: { "test_part" => { "heading" => "body", "body" => "<div>Old content</div>" } },
          current_content: { "test_part" => { "heading" => "body", "body" => "<div>New content</div>" } },
        )
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
        FactoryBot.create(
          :request,
          :with_collaborator,
          collaborator: test_user,
          source_title: "Example title",
          deadline: Time.zone.now + 5.days,
          previous_content: { "test_part" => { "heading" => "body", "body" => "<div>Old content</div>" } },
          current_content: { "test_part" => { "heading" => "body", "body" => "<div>New content</div>" } },
        )
      end

      describe "GET /compare" do
        it "does not render the Response button" do
          get compare_path(source_app: request.source_app, source_id: request.source_id)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include(I18n.t("fact_check_comparison.respond_to_button"))
        end

        it "does not render the Response by field" do
          get compare_path(source_app: request.source_app, source_id: request.source_id)

          expect(response).to have_http_status(:ok)
          expect(response.body).not_to include(I18n.t("fact_check_comparison.respond_by"))
        end

        it "does render a warning callout" do
          get compare_path(source_app: request.source_app, source_id: request.source_id)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Only the person coordinating the fact check can submit it to GDS.")
        end
      end
    end
    context "when draft origin fields are present" do
      let(:previous_content) { { "test_part" => { "heading" => "body", "body" => "<div>Old content</div>" } } }
      let(:current_content) { { "test_part" => { "heading" => "body", "body" => "<div>New content</div>" } } }

      it "includes a draft origin preview link with a JWT token" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response.body).to include("draft-origin.dev.gov.uk/#{request.draft_slug}")
        expect(response.body).to include("token=")
      end
    end

    context "when draft origin fields are not present" do
      let(:request) do
        create(
          :request,
          draft_content_id: nil,
          draft_auth_bypass_id: nil,
          draft_slug: nil,
          previous_content: { "test_part" => { "heading" => "body", "body" => "<div>Old content</div>" } },
          current_content: { "test_part" => { "heading" => "body", "body" => "<div>New content</div>" } },
        )
      end

      it "does not render the preview section" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(I18n.t("fact_check_comparison.preview_heading"))
        expect(response.body).not_to include(I18n.t("fact_check_comparison.preview_link"))
      end
    end

    let(:parsed) do
      doc = Nokogiri::HTML(response.body)
      {
        ins: doc.css("div.compare-editions ins").map { |n| n.text.strip },
        del: doc.css("div.compare-editions del").map { |n| n.text.strip },
        diff: doc.css("div.compare-editions div").map { |n| n.text.squish }.reject(&:empty?),
        heading: doc.css("div.gem-c-govspeak h3").map { |n| n.text.strip },
      }
    end

    context "when no request exists for the given source_app and source_id" do
      it "returns 404" do
        get compare_path(source_app: "invalid", source_id: "invalid")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with one part" do
      let(:current_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } } }

      before do
        get compare_path(source_app: request.source_app, source_id: request.source_id)
      end

      context "with differing previous_content and current_content" do
        let(:previous_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } } }

        it "correctly renders the formatted diff" do
          verify_static_elements
          verify_unchanged(parsed, ["This is the unchanged line."])
          verify_ins(parsed, ["This line has changes"])
          verify_del(parsed, ["This line will be changed"])
          expect(response.body).not_to include("heading_not_shown")
        end
      end

      context "with identical current_content and previous_content" do
        let(:previous_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } } }

        it "correctly renders the formatted diff" do
          verify_static_elements
          verify_unchanged(parsed, ["This is the unchanged line.", "This line has changes"])
          expect(parsed[:del]).to eq([])
          expect(parsed[:ins]).to eq([])
          expect(response.body).not_to include("heading_not_shown")
        end
      end

      context "with no previous_content" do
        let(:previous_content) { nil }

        it "correctly renders the formatted diff" do
          verify_static_elements
          verify_unchanged(parsed, ["This is the unchanged line.", "This line has changes"])
          expect(parsed[:del]).to eq([])
          expect(parsed[:ins]).to eq([])
          expect(response.body).not_to include("heading_not_shown")
        end
      end
    end

    context "with two parts" do
      before do
        get compare_path(source_app: request.source_app, source_id: request.source_id)
      end

      context "with differing previous_content and current_content" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 unchanged.</div><div>Part 1 to be changed.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 unchanged.</div><div>Part 2 to be changed.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 unchanged.</div><div>Part 1 changed.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 unchanged.</div><div>Part 2 changed.</div>" } }
        end

        it "correctly renders the formatted diff" do
          verify_static_elements
          verify_unchanged(parsed, ["Part 1 unchanged.", "Part 2 unchanged."])
          verify_del(parsed, ["Part 1 to be changed.", "Part 2 to be changed."])
          verify_ins(parsed, ["Part 1 changed.", "Part 2 changed."])
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading"])
        end
      end

      context "when the first part is removed" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end
        let(:current_content) { { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } } }

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading (REMOVED)", "Part 2 heading"])
        end

        it "displays the part as removed" do
          verify_del(parsed, ["Part 1."])
        end
      end

      context "when the second part is removed" do
        let(:current_content) { { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" } } }
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (REMOVED)"])
        end

        it "displays the part as removed" do
          verify_del(parsed, ["Part 2."])
        end
      end

      context "when the first part is a new addition" do
        let(:previous_content) { { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } } }
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 new part</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading (ADDED)", "Part 2 heading"])
        end

        it "displays the part as added" do
          expect(parsed[:ins]).to eq(["Part 1 new part"])
        end
      end

      context "when the second part is a new addition" do
        let(:previous_content) { { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" } } }
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 new part</div>" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (ADDED)"])
        end

        it "displays the part as added" do
          expect(parsed[:ins]).to eq(["Part 2 new part"])
        end
      end

      context "when the two parts swap positions" do
        let(:previous_content) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end

        it "uses the order from current_content" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading"])
        end
      end
    end

    context "with three parts" do
      before do
        get compare_path(source_app: request.source_app, source_id: request.source_id)
      end

      context "when all parts are in previous and current" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 unchanged.</div><div>Part 1 to be changed.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 unchanged.</div><div>Part 2 to be changed.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3 unchanged.</div><div>Part 3 to be changed.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 unchanged.</div><div>Part 1 changed.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 unchanged.</div><div>Part 2 changed.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3 unchanged.</div><div>Part 3 changed.</div>" } }
        end

        it "correctly renders the formatted diff" do
          verify_static_elements
          verify_unchanged(parsed, ["Part 1 unchanged.", "Part 2 unchanged.", "Part 3 unchanged."])
          verify_del(parsed, ["Part 1 to be changed.", "Part 2 to be changed.", "Part 3 to be changed."])
          verify_ins(parsed, ["Part 1 changed.", "Part 2 changed.", "Part 3 changed."])
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading", "Part 3 heading"])
        end
      end
      context "when the first part is a new addition" do
        let(:previous_content) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading (ADDED)", "Part 2 heading", "Part 3 heading"])
        end

        it "displays the part as added" do
          verify_ins(parsed, ["Part 1."])
        end
      end

      context "when the second part is a new addition" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (ADDED)", "Part 3 heading"])
        end

        it "displays the part as added" do
          verify_ins(parsed, ["Part 2."])
        end
      end

      context "when the third part is a new addition" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading", "Part 3 heading (ADDED)"])
        end

        it "displays the part as added" do
          verify_ins(parsed, ["Part 3."])
        end
      end

      context "when the first part is removed" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading (REMOVED)", "Part 2 heading", "Part 3 heading"])
        end

        it "displays the part as removed" do
          verify_del(parsed, ["Part 1."])
        end
      end

      context "when the second part is removed" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (REMOVED)", "Part 3 heading"])
        end

        it "displays the part as removed" do
          verify_del(parsed, ["Part 2."])
        end
      end

      context "when the third part is removed" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading", "Part 3 heading (REMOVED)"])
        end

        it "displays the part as removed" do
          verify_del(parsed, ["Part 3."])
        end
      end

      context "when two parts are swapped" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" } }
        end
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_3" => { "heading" => "Part 3 heading", "body" => "<div>Part 3.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end

        it "uses the order from current_content" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 3 heading", "Part 2 heading"])
        end
      end

      it "does not render the Response by field" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(I18n.t("fact_check_comparison.respond_by"))
      end

      it "does render a warning callout" do
        get compare_path(source_app: request.source_app, source_id: request.source_id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Only the person coordinating the fact check can submit it to GDS.")
      end
    end
  end
end
