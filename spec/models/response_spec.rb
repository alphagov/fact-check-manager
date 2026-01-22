require "rails_helper"

RSpec.describe Response, type: :model do
  it "is not valid without required associations/attributes" do
    record = described_class.new

    expect(record).not_to be_valid
  end

  it "includes errors for each missing attribute" do
    record = described_class.new
    record.valid?

    expect(record.errors.attribute_names).to include(:request)
    expect(record.errors.attribute_names).to include(:user)
    expect(record.errors.attribute_names).to include(:body)
  end

  it "is valid when all required associations/attributes exist" do
    response = FactoryBot.build(:response)

    expect(response).to be_valid
  end

  describe "validations" do
    it "validates that there can only be one response per request" do
      existing_response = FactoryBot.create(:response)
      user = FactoryBot.create(:user)
      duplicate_response = FactoryBot.build(:response, request: existing_response.request, user: user)

      expect(duplicate_response).not_to be_valid
      expect(duplicate_response.errors[:request_id]).to include("has already been responded to")
    end
  end

  describe "associations" do
    it "allows a request to return the response object" do
      request = FactoryBot.create(:request)
      response = FactoryBot.create(:response, request: request)

      expect(request.response).to equal(response)
    end
  end
end
