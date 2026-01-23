require "rails_helper"

RSpec.describe Request, type: :model do
  it "is not valid without required attributes" do
    record = described_class.new

    expect(record).not_to be_valid
  end

  it "includes errors for each missing attribute" do
    record = described_class.new
    record.valid?

    expect(record.errors.attribute_names).to include(:edition_id, :requester_name, :requester_email, :current_content, :deadline)
  end

  it "is valid when all required attributes are set" do
    record = FactoryBot.build(:request)

    expect(record).to be_valid
  end

  describe "searching by edition_id" do
    it "can save and retrieve multiple requests that share the same edition_id" do
      shared_uuid = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"

      request_1 = create(:request, edition_id: shared_uuid, requester_email: "alice@gov.uk")
      request_2 = create(:request, edition_id: shared_uuid, requester_email: "bob@gov.uk")
      other_request = create(:request, edition_id: SecureRandom.uuid)
      results = Request.where(edition_id: shared_uuid)

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
end
