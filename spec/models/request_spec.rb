require "rails_helper"

RSpec.shared_examples "test JSON content" do |content_field|
  context "when #{content_field} is not a hash" do
    it "is invalid" do
      invalid_content = false
      record = FactoryBot.build(:request, **{ content_field => invalid_content })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("#{content_field} must be a hash")
    end

    it "adds an error to #{content_field}" do
      invalid_content = "[\"apple\", \"banana\", \"kiwi\"]"
      record = FactoryBot.build(:request, **{ content_field => invalid_content })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("#{content_field} must be a hash")
    end
  end

  context "when #{content_field} contains non hash values as top level value" do
    it "is invalid" do
      invalid_content = false
      record = FactoryBot.build(:request, **{ content_field => { "id": invalid_content } })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("value for id must be a hash")
    end

    it "adds an error to #{content_field}" do
      invalid_content = "[\"apple\", \"banana\", \"kiwi\"]"
      record = FactoryBot.build(:request, **{ content_field => { "id": invalid_content } })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("value for id must be a hash")
    end
  end

  context "when #{content_field} contains non string values as bottom level values" do
    it "is invalid" do
      invalid_content = { "illegal_boolean": false }
      record = FactoryBot.build(:request, **{ content_field => { "id1": { "heading1": invalid_content } } })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("block id1 must contain exactly one heading:body pair")
    end

    it "adds an error to #{content_field}" do
      invalid_content = %w[apple banana kiwi]
      record = FactoryBot.build(:request, **{ content_field => { "id1": { "heading1": invalid_content } } })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("block id1 must contain exactly one heading:body pair")
    end
  end

  context "when #{content_field} bottom level hash contains too many items" do
    it "is invalid and adds an error to #{content_field}" do
      overpopulated_content = { "heading1": "content", "heading2": "content" }
      record = FactoryBot.build(:request, **{ content_field => { "id1": overpopulated_content } })

      expect(record).not_to be_valid
      expect(record.errors.messages[content_field]).to include("block id1 must contain exactly one heading:body pair")
    end
  end
end

RSpec.describe Request, type: :model do
  context "when missing required attributes" do
    it "is invalid" do
      record = described_class.new

      expect(record).not_to be_valid
    end

    it "includes errors for each missing required attribute" do
      record = described_class.new

      expect(record).not_to be_valid
      expect(record.errors.attribute_names).to include(:source_id, :source_app, :requester_name, :requester_email, :current_content)
    end
  end

  context "when current_content is an empty hash" do
    it "raises an error " do
      record = FactoryBot.build(:request, current_content: {})

      expect(record).not_to be_valid
      expect(record.errors.attribute_names).to include(:current_content)
      expect(record.errors.messages[:current_content]).to include("can't be blank")
    end
  end

  include_examples "test JSON content", :current_content
  include_examples "test JSON content", :previous_content

  context "when all required attributes are set" do
    it "is valid" do
      record = FactoryBot.build(:request)

      expect(record).to be_valid
    end
  end

  context "when zendesk_number is not a string of digits" do
    it "is not valid" do
      ["not a number", "123invalid4", "#1234567", "1234567#"].each do |zendesk_number|
        record = FactoryBot.build(:request, zendesk_number: zendesk_number)

        expect(record).not_to be_valid
        expect(record.errors.full_messages).to include("Zendesk number must be at least 7 digits long")
      end
    end
  end

  context "when zendesk_number is too short" do
    it "is not valid" do
      record = FactoryBot.build(:request, zendesk_number: "123456")

      expect(record).not_to be_valid
      expect(record.errors.full_messages).to include("Zendesk number must be at least 7 digits long")
    end
  end

  context "when zendesk_number starts with zero" do
    it "is not valid" do
      record = FactoryBot.build(:request, zendesk_number: "0123456")

      expect(record).not_to be_valid
      expect(record.errors.full_messages).to include("Zendesk number cannot start with zero")
    end
  end

  context "when zendesk_number is an empty string" do
    it "is normalized to nil" do
      record = FactoryBot.build(:request, zendesk_number: "")

      expect(record).to be_valid
      expect(record.zendesk_number).to be_nil
    end
  end

  context "when zendesk_number is more than 10 digits" do
    it "is valid and stored without overflowing" do
      record = FactoryBot.build(:request, zendesk_number: "21474836470123456789")

      expect(record).to be_valid
      record.save!
      expect(record.reload.zendesk_number).to eq("21474836470123456789")
    end
  end

  context "when content hashes contain multiple key-value-pairs" do
    it "is valid" do
      record = FactoryBot.build(:request, :with_more_complex_content_data)

      expect(record).to be_valid
    end
  end

  describe "requester_email" do
    context "when the email address is not in a valid format" do
      it "is not valid" do
        %w[user@-example.com user@example-.com invalid@@example.com gemma@government].each do |invalid_email|
          record = FactoryBot.build(:request, requester_email: invalid_email)

          expect(record).not_to be_valid
          expect(record.errors.full_messages).to include("Requester email must be a valid email address")
        end
      end
    end

    context "when the email address is in a valid format" do
      it "is valid" do
        %w[o'connor@example.com
           john.smith@example.com
           john+newsletter@example.com
           foo_bar@example.com
           phoebe.smith@digital.this-dept.gov.uk].each do |valid_email|
          record = FactoryBot.build(:request, requester_email: valid_email)

          expect(record).to be_valid
        end
      end
    end
  end

  describe "deadline" do
    context "when blank" do
      it "is not valid" do
        record = FactoryBot.build(:request, deadline: nil)

        expect(record).not_to be_valid
        expect(record.errors.full_messages).to include("Deadline can't be blank")
      end

      context "when in the past" do
        it "is not valid" do
          record = FactoryBot.build(:request, deadline: 1.year.ago)

          expect(record).not_to be_valid
          expect(record.errors.full_messages).to include("Deadline must be a date between now and 10 years in the future")
        end
      end

      context "when over 10 years in the future" do
        it "is not valid" do
          record = FactoryBot.build(:request, deadline: 10.years.from_now + 1.day)

          expect(record).not_to be_valid
          expect(record.errors.full_messages).to include("Deadline must be a date between now and 10 years in the future")
        end
      end
    end

    context "should be valid" do
      it "if is a future date within the next 10 years" do
        record = FactoryBot.build(:request, deadline: 1.week.from_now)

        expect(record).to be_valid
      end
    end
  end

  describe "source_url" do
    it "is valid when it is has a valid URL format" do
      %w[https://www.gov.uk/help
         https://www.gov.uk/government/organisations/dsit
         https://www.gov.uk/search?q=ruby
         https://example.com?page=1&sort=name].each do |valid_url|
        record = FactoryBot.build(:request, deadline: 1.year.from_now, source_url: valid_url)

        expect(record).to be_valid
      end
    end

    it "is invalid when it does not have a valid URL format" do
      %w[www.gov.uk example.com ://example.com https//example.com].each do |invalid_url|
        record = FactoryBot.build(:request, deadline: 1.year.from_now, source_url: invalid_url)

        expect(record).not_to be_valid
        expect(record.errors.full_messages).to include("Source URL must be a valid URL")
      end
    end

    it "is invalid if it doesn't use either http or https" do
      %w[ftp://example.com file:///tmp/report.pdf mailto:test@example.com ssh://server.internal].each do |url_with_bad_scheme|
        record = FactoryBot.build(:request, deadline: 1.year.from_now, source_url: url_with_bad_scheme)

        expect(record).not_to be_valid
        expect(record.errors.full_messages).to include("Source URL must use either http or https")
      end
    end
  end

  describe "searching by source_id" do
    it "can save and retrieve multiple requests that share the same source_id" do
      shared_uuid = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
      request_1 = create(:request, source_id: shared_uuid, requester_email: "alice@gov.uk")
      request_2 = create(:request, source_id: shared_uuid, requester_email: "bob@gov.uk")
      other_request = create(:request, source_id: SecureRandom.uuid)

      results = Request.where(source_id: shared_uuid)

      expect(results).to include(request_1, request_2)
      expect(results).not_to include(other_request)
      expect(results.count).to eq(2)
    end
  end

  describe "associations" do
    it "returns a list of related collaborations" do
      record = FactoryBot.create(:request)
      collaboration_1 = FactoryBot.create(:collaboration, request: record)
      collaboration_2 = FactoryBot.create(:collaboration,
                                          request: record)

      expect(record.collaborations).to include(collaboration_1, collaboration_2)
    end
  end

  describe "#formatted_deadline" do
    it "formats the deadline as a long date" do
      record = FactoryBot.build(:request, deadline: Time.zone.parse("2026-06-12"))

      expect(record.formatted_deadline).to eq("Friday 12 June 2026")
    end
  end

  describe "#first_edition?" do
    it "returns true when previous_content is nil" do
      record = FactoryBot.build(:request, previous_content: nil)

      expect(record.first_edition?).to be(true)
    end

    it "returns true when previous_content is an empty hash" do
      record = FactoryBot.build(:request, previous_content: {})

      expect(record.first_edition?).to be(true)
    end

    it "returns false when previous_content is present" do
      record = FactoryBot.build(:request, previous_content: { "id_value" => { "heading" => "test_heading", "body" => "<p>Previous content</p>" } })

      expect(record.first_edition?).to be(false)
    end
  end

  describe ".most_recent_for_source" do
    it "returns the most recent request for the given source app and source ID" do
      source_id = SecureRandom.uuid
      source_app = "app"
      _older_request = FactoryBot.create(:request, source_app: source_app, source_id: source_id, created_at: Time.zone.now - 2.hours)
      newer_request = FactoryBot.create(:request, source_app: source_app, source_id: source_id, created_at: Time.zone.now)
      _newer_non_source_request = FactoryBot.create(:request, source_id: SecureRandom.uuid)

      request = Request.most_recent_for_source(source_app:, source_id:)

      expect(request).to eq(newer_request)
    end

    it "returns nil if source_app is not matched" do
      source_id = SecureRandom.uuid
      source_app = "app"
      alt_source_app = "app2"

      FactoryBot.create(:request, source_app: alt_source_app, source_id: source_id, created_at: Time.zone.now)

      expect(Request.most_recent_for_source(source_app:, source_id:)).to be_nil
    end

    it "returns nil if source_id is not matched" do
      source_id = SecureRandom.uuid
      source_app = "app"
      alt_source_id = SecureRandom.uuid

      FactoryBot.create(:request, source_app: source_app, source_id: alt_source_id, created_at: Time.zone.now)

      expect(Request.most_recent_for_source(source_app:, source_id:)).to be_nil
    end

    it "returns nil if neither source_app or source_id is matched" do
      source_id = SecureRandom.uuid
      source_app = "app"
      alt_source_id = SecureRandom.uuid
      alt_source_app = "app2"

      FactoryBot.create(:request, source_app: alt_source_app, source_id: alt_source_id, created_at: Time.zone.now)

      expect(Request.most_recent_for_source(source_app:, source_id:)).to be_nil
    end
  end
end
