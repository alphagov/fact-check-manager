require "rails_helper"

RSpec.describe TokenHelper, type: :helper do
  include ActiveSupport::Testing::TimeHelpers

  let(:request_record) { FactoryBot.build(:request) }

  describe "#generate_preview_link" do
    it "returns the correctly nested path with the token" do
      allow(helper).to receive(:requests_preview_path).and_return("/requests/publisher/123/preview")

      link = helper.generate_preview_link(request_record)
      expect(link).to include("/requests/publisher/123/preview?token=")
    end
  end

  describe "#valid_jwt?" do
    let(:valid_token) { helper.jwt_token(request_record) }

    it "returns true for a valid token" do
      expect(helper.valid_jwt?(valid_token, request_record)).to be true
    end

    it "returns false for an expired token" do
      expired_token = travel_to(2.months.ago) do
        helper.jwt_token(request_record)
      end

      expect(Rails.logger).to receive(:error).with(/Error JWT::ExpiredSignature/)
      expect(helper.valid_jwt?(expired_token, request_record)).to be false
    end

    it "returns false for an invalid sub" do
      second_request = FactoryBot.build(:request)

      expect(Rails.logger).to receive(:error).with(/Error JWT::InvalidSubError/)
      expect(helper.valid_jwt?(valid_token, second_request)).to be false
    end

    it "returns false for an invalid algorithm" do
      payload = {
        "source_app" => request_record.source_app,
        "source_id" => request_record.source_id,
        "sub" => request_record.auth_bypass_id,
        "iat" => Time.zone.now.to_i,
        "exp" => 1.month.from_now.to_i,
      }
      diff_algorithm_token = JWT.encode(payload, jwt_auth_secret, "HS384")

      expect(Rails.logger).to receive(:error).with(/Error JWT::IncorrectAlgorithm/)
      expect(helper.valid_jwt?(diff_algorithm_token, request_record)).to be false
    end

    it "fails gracefully and returns false for a malformed token" do
      allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)

      expect(Rails.logger).to receive(:error).with(/Error JWT::DecodeError/)
      expect(helper.valid_jwt?(valid_token, request_record)).to be false
    end
  end

  describe "#token_matches_request?" do
    it "matches correctly when keys are stringified" do
      payload = [{
        "source_app" => request_record.source_app,
        "source_id" => request_record.source_id,
      }]

      expect(helper.token_matches_request?(payload, request_record)).to be true
    end

    it "returns false when source_app doesn't match" do
      payload = [{
        "source_app" => "random app",
        "source_id" => request_record.source_id,
      }]

      expect(helper.token_matches_request?(payload, request_record)).to be false
    end

    it "returns false when source_id doesn't match" do
      payload = [{
        "source_app" => request_record.source_app,
        "source_id" => SecureRandom.uuid,
      }]

      expect(helper.token_matches_request?(payload, request_record)).to be false
    end

    it "returns false when source_app is nil" do
      payload = [{
        "source_app" => nil,
        "source_id" => request_record.source_id,
      }]

      expect(helper.token_matches_request?(payload, request_record)).to be false
    end

    it "returns false when source_id is nil" do
      payload = [{
        "source_app" => request_record.source_app,
        "source_id" => nil,
      }]

      expect(helper.token_matches_request?(payload, request_record)).to be false
    end
  end
end
