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

  describe "#accepted" do
    %w[true false].each do |boolean_value|
      it "is valid if either true or false" do
        response = FactoryBot.build(:response, accepted: boolean_value)

        expect(response).to be_valid
      end
    end

    it "is invalid if nil" do
      response = FactoryBot.build(:response, accepted: nil)

      expect(response).not_to be_valid
      expect(response.errors[:accepted]).to include("must be true or false")
    end

    context "if false and body is not present" do
      it "is invalid" do
        response = FactoryBot.build(:response, accepted: false, body: nil)

        expect(response).not_to be_valid
        expect(response.errors[:body]).to include("cannot be blank if accepted is false")
      end
    end

    context "if true" do
      it "is valid with an empty body" do
        response = FactoryBot.build(:response, accepted: true)

        expect(response).to be_valid
      end
    end
  end

  describe "#body" do
    it "must be present if accepted is false" do
      response = FactoryBot.build(:response, accepted: false, body: nil)

      expect(response).not_to be_valid
      expect(response.errors[:body]).to include("cannot be blank if accepted is false")
    end

    it "can be empty if accepted is true" do
      response = FactoryBot.build(:response, accepted: true)

      expect(response).to be_valid
    end
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

    it "allows a user to return a collection of response objects" do
      user = FactoryBot.create(:user)
      first_request_response = FactoryBot.create(:response, user: user)
      second_request_response = FactoryBot.create(:response, user: user)

      expect(user.responses).to include(first_request_response)
      expect(user.responses).to include(second_request_response)
    end
  end
end
