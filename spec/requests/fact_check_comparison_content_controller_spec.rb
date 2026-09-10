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
        previous_markdown: previous_markdown,
        current_markdown: current_markdown,
      )
    end

    let(:parsed) do
      doc = Nokogiri::HTML(response.body)
      {
        ins: doc.css("div.compare-markdown ins").map { |n| n.text.strip },
        del: doc.css("div.compare-markdown del").map { |n| n.text.strip },
        heading: doc.css("div.compare-markdown.gem-c-govspeak h2").map { |n| n.text.strip },
      }
    end

    context "govspeak with one part" do
      let(:current_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } } }
      let(:current_markdown) { { "test_id" => { "heading" => "heading_not_shown", "body" => "# This is the unchanged line. This line has changes" } } }

      before do
        get "#{compare_path(source_app: request.source_app, source_id: request.source_id)}#markdown-view"
      end

      context "with differing previous_content and current_content" do
        let(:previous_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line will be changed</div>" } } }
        let(:previous_markdown) { { "test_id" => { "heading" => "heading_not_shown", "body" => "# This is the unchanged line. This line will be changed" } } }

        it "correctly renders the formatted diff" do
          verify_static_elements
          expect(response.body).to include("<del># This is the unchanged line. This line <strong>will be</strong> change<strong>d</strong></del>")
          expect(response.body).to include("<ins># This is the unchanged line. This line <strong>has</strong> change<strong>s</strong></ins>")
          expect(response.body).not_to include("heading_not_shown")
        end
      end

      context "with identical current_content and previous_content" do
        let(:previous_content) { { "test_id" => { "heading" => "heading_not_shown", "body" => "<div>This is the unchanged line.</div><div>This line has changes</div>" } } }
        let(:previous_markdown) { { "test_id" => { "heading" => "heading_not_shown", "body" => "# This is the unchanged line. This line has changes" } } }

        it "correctly renders the formatted diff" do
          verify_static_elements
          expect(response.body).to include('<li class="unchanged"><span># This is the unchanged line. This line has changes</span></li>')
          expect(response.body).not_to include("<del>")
          expect(response.body).not_to include("<ins>")
          expect(response.body).not_to include("heading_not_shown")
        end
      end

      context "with no previous_content" do
        let(:previous_content) { nil }
        let(:previous_markdown) { nil }

        it "correctly renders the formatted diff" do
          verify_static_elements(first_edition: true)
          expect(response.body).to include('<li class="unchanged"><span># This is the unchanged line. This line has changes</span></li>')
          expect(response.body).not_to include("<del>")
          expect(response.body).not_to include("<ins>")
          expect(response.body).not_to include("heading_not_shown")
        end
      end

      context "with empty previous_content" do
        let(:previous_content) { {} }
        let(:previous_markdown) { {} }

        it "correctly renders the formatted diff" do
          verify_static_elements(first_edition: true)
          expect(response.body).to include('<li class="unchanged"><span># This is the unchanged line. This line has changes</span></li>')
          expect(response.body).not_to include("<del>")
          expect(response.body).not_to include("<ins>")
          expect(response.body).not_to include("heading_not_shown")
        end
      end
    end

    context "govspeak with two parts" do
      before do
        get "#{compare_path(source_app: request.source_app, source_id: request.source_id)}#markdown-view"
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1 unchanged. Part 1 to be changed." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2 unchanged. Part 2 to be changed." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1 unchanged. Part 1 changed." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2 unchanged. Part 2 changed." } }
        end

        it "correctly renders the formatted diff" do
          verify_static_elements
          markdown_verify_del(parsed, ["# Part 1 unchanged. Part 1 to be changed.", "# Part 2 unchanged. Part 2 to be changed."])
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading"])
        end
      end

      context "when the first part is removed" do
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end
        let(:current_content) { { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } } }
        let(:previous_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end
        let(:current_markdown) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading (REMOVED)", "Part 2 heading"])
        end

        it "displays the part as removed" do
          markdown_verify_del(parsed, ["# Part 1."])
        end
      end

      context "when the second part is removed" do
        let(:current_content) { { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" } } }
        let(:previous_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end
        let(:previous_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (REMOVED)"])
        end

        it "displays the part as removed" do
          markdown_verify_del(parsed, ["# Part 2."])
        end
      end

      context "when the first part is a new addition" do
        let(:previous_content) { { "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } } }
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1 new part</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2.</div>" } }
        end
        let(:previous_markdown) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1 new part" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading (ADDED)", "Part 2 heading"])
        end

        it "displays the part as added" do
          expect(parsed[:ins].first).to include("# Part 1 new part")
        end
      end

      context "when the second part is a new addition" do
        let(:previous_content) { { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" } } }
        let(:current_content) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "<div>Part 1.</div>" },
            "part_2" => { "heading" => "Part 2 heading", "body" => "<div>Part 2 new part</div>" } }
        end
        let(:previous_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2 new part" } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading (ADDED)"])
        end

        it "displays the part as added" do
          expect(parsed[:ins].first).to include("# Part 2 new part")
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
        let(:previous_markdown) do
          { "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." },
            "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "Part 2 heading", "body" => "# Part 2." } }
        end

        it "uses the order from current_content" do
          verify_headings_order(parsed, ["Part 1 heading", "Part 2 heading"])
        end
      end
    end

    context "govspeak with three parts" do
      before do
        get "#{compare_path(source_app: request.source_app, source_id: request.source_id)}#markdown-view"
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1 unchanged. Part 1 to be changed." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2 unchanged. Part 2 to be changed." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3 unchanged. Part 3 to be changed." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1 unchanged. Part 1 changed." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2 unchanged. Part 2 changed." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3 unchanged. Part 3 changed." } }
        end

        it "correctly renders the formatted diff" do
          verify_static_elements
          markdown_verify_del(parsed, ["# Part 1 unchanged. Part 1 to be changed.", "# Part 2 unchanged. Part 2 to be changed.", "# Part 3 unchanged. Part 3 to be changed."])
          markdown_verify_ins(parsed, ["# Part 1 unchanged. Part 1 changed.", "# Part 2 unchanged. Part 2 changed.", "# Part 3 unchanged. Part 3 changed."])
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 2 heading", "# Part 3 heading"])
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
        let(:previous_markdown) do
          { "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["# Part 1 heading (ADDED)", "# Part 2 heading", "# Part 3 heading"])
        end

        it "displays the part as added" do
          markdown_verify_ins(parsed, ["# Part 1."])
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 2 heading (ADDED)", "# Part 3 heading"])
        end

        it "displays the part as added" do
          markdown_verify_ins(parsed, ["# Part 2."])
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

        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end

        it "displays the heading of the added part" do
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 2 heading", "# Part 3 heading (ADDED)"])
        end

        it "displays the part as added" do
          markdown_verify_ins(parsed, ["# Part 3."])
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["# Part 1 heading (REMOVED)", "# Part 2 heading", "# Part 3 heading"])
        end

        it "displays the part as removed" do
          markdown_verify_del(parsed, ["# Part 1."])
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 2 heading (REMOVED)", "# Part 3 heading"])
        end

        it "displays the part as removed" do
          markdown_verify_del(parsed, ["# Part 2."])
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." } }
        end

        it "displays the heading of the removed part" do
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 2 heading", "# Part 3 heading (REMOVED)"])
        end

        it "displays the part as removed" do
          markdown_verify_del(parsed, ["# Part 3."])
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
        let(:previous_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." } }
        end
        let(:current_markdown) do
          { "part_1" => { "heading" => "# Part 1 heading", "body" => "# Part 1." },
            "part_3" => { "heading" => "# Part 3 heading", "body" => "# Part 3." },
            "part_2" => { "heading" => "# Part 2 heading", "body" => "# Part 2." } }
        end

        it "uses the order from current_content" do
          verify_headings_order(parsed, ["# Part 1 heading", "# Part 3 heading", "# Part 2 heading"])
        end
      end
    end
  end
end
