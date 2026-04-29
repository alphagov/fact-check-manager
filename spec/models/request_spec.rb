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

  context "when zendesk_number is not a number" do
    it "is not valid" do
      record = FactoryBot.build(:request, zendesk_number: "not a number")

      expect(record).not_to be_valid
    end
  end

  context "when zendesk_number is too short" do
    it "is not valid" do
      record = FactoryBot.build(:request, zendesk_number: 1)

      expect(record).not_to be_valid
    end
  end

  context "when content hashes contain multiple key-value-pairs" do
    it "is valid" do
      record = FactoryBot.build(:request, :with_more_complex_content_data)

      expect(record).to be_valid
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
