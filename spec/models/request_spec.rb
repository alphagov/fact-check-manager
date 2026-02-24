require "rails_helper"

RSpec.shared_examples "test JSON content" do |content_field|
  it "#{content_field} contains non string values" do
    invalid_hash_content = { "illegal_boolean": false }
    record = FactoryBot.build(:request, **{ content_field => invalid_hash_content })
    record.validate

    expect(record).not_to be_valid
    expect(record.errors.messages[content_field]).to include("value for illegal_boolean must be a string")
  end

  it "it adds an error to #{content_field}" do
    invalid_hash_content = "[\"apple\", \"banana\", \"kiwi\"]"
    record = FactoryBot.build(:request, **{ content_field => invalid_hash_content })
    record.validate

    expect(record).not_to be_valid
    expect(record.errors.messages[content_field]).to include("#{content_field} is not a hash")
  end
end

RSpec.describe Request, type: :model do
  context "is invalid" do
    it "without required attributes" do
      record = described_class.new

      expect(record).not_to be_valid
    end

    it "and includes errors for each missing mandatory attribute" do
      record = described_class.new
      record.validate

      expect(record.errors.attribute_names).to include(:source_id, :source_app, :requester_name, :requester_email, :current_content)
    end

    it "current_content is an empty hash" do
      record = FactoryBot.build(:request, current_content: {})
      record.validate

      expect(record).not_to be_valid
      expect(record.errors.attribute_names).to include(:current_content)
      expect(record.errors.messages[:current_content]).to include("can't be blank")
    end

    include_examples "test JSON content", :previous_content
    include_examples "test JSON content", :current_content
  end

  context "is valid" do
    it "when all required attributes are set" do
      record = FactoryBot.build(:request)

      expect(record).to be_valid
    end

    it "when content hashes contain multiple key-value-pairs" do
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

  context "scopes" do
    describe ".for_source" do
      it "returns only requests matching the given source id" do
        source_id = SecureRandom.uuid
        source_request = FactoryBot.create(:request, source_id: source_id)
        other_source_request = FactoryBot.create(:request)

        requests = Request.for_source(source_id)

        expect(requests).to include(source_request)
        expect(requests).not_to include(other_source_request)
      end
    end

    describe ".most_recent_first" do
      it "returns requests in descending order of created_at" do
        source_id = SecureRandom.uuid
        older_request = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now - 2.hours)
        newer_request = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now)

        requests = Request.most_recent_first

        expect(requests).to eq([newer_request, older_request])
      end

      it "combines with .for_source to return source requests in descending order" do
        source_id = SecureRandom.uuid
        older_request_for_source = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now - 2.hours)
        newer_request_for_source = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now)
        older_request_other_source = FactoryBot.create(:request, created_at: Time.zone.now - 2.days)
        newer_request_other_source = FactoryBot.create(:request, created_at: Time.zone.now)

        requests = Request.for_source(source_id).most_recent_first

        expect(requests).to eq([newer_request_for_source, older_request_for_source])
        expect(requests).not_to include(older_request_other_source, newer_request_other_source)
      end
    end

    describe ".most_recent_for_source" do
      it "returns the most recent request for the given source ID" do
        source_id = SecureRandom.uuid
        _older_request = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now - 2.hours)
        newer_request = FactoryBot.create(:request, source_id: source_id, created_at: Time.zone.now)

        request = Request.most_recent_for_source source_id

        expect(request).to eq(newer_request)
      end
    end
  end
end
