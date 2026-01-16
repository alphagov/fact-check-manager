require "rails_helper"

RSpec.describe Collaboration, type: :model do
  it "is not valid without required associations/attributes" do
    record = described_class.new

    expect(record).not_to be_valid
  end

  it "includes errors for each missing attribute" do
    record = described_class.new
    record.valid?

    expect(record.errors.attribute_names).to include(:request)
    expect(record.errors.attribute_names).to include(:user)
    expect(record.errors.attribute_names).to include(:role)
  end

  it "is valid when all required associations/attributes exist" do
    record = FactoryBot.build(:collaboration)

    expect(record).to be_valid
  end

  describe "validations" do
    it "validates that a user can only have one collaboration per request" do
      existing_collaboration = FactoryBot.create(:collaboration)
      duplicate_collaboration = FactoryBot.build(:collaboration,
                                                 user: existing_collaboration.user,
                                                 request: existing_collaboration.request)

      expect(duplicate_collaboration).not_to be_valid
      expect(duplicate_collaboration.errors[:user_id]).to include("is already a collaborator on this request")
    end
  end

  describe "associations" do
    it "allows request to return a collection of user objects" do
      shared_request = FactoryBot.create(:request)
      collaboration_1 = FactoryBot.create(:collaboration, request: shared_request)
      collaboration_2 = FactoryBot.create(:collaboration, request: shared_request)

      expect(shared_request.users).to include(collaboration_1.user)
      expect(shared_request.users).to include(collaboration_2.user)
    end
  end
end
