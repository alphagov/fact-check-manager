require "rails_helper"

RSpec.describe TokenHelper, type: :helper do
  include ActiveSupport::Testing::TimeHelpers

  let(:request_record) { FactoryBot.build(:request) }

  describe "#generate_preview_link" do
    it "returns the correctly nested path with the token" do
      allow(helper).to receive(:compare_path).and_return("/requests/publisher/123/compare")

      link = helper.generate_compare_preview_link(request_record)
      expect(link).to include("/requests/publisher/123/compare?token=#{helper.compare_preview_jwt_token(request_record)}")
    end
  end

  describe "#valid_compare_preview_jwt?" do
    let(:valid_token) { helper.compare_preview_jwt_token(request_record) }

    it "returns true for a valid token" do
      expect(helper.valid_compare_preview_jwt?(valid_token, request_record)).to be true
    end

    it "returns false for an expired token" do
      expired_token = travel_to(2.months.ago) do
        helper.compare_preview_jwt_token(request_record)
      end

      expect(Rails.logger).to receive(:error).with(/Error JWT::ExpiredSignature/)
      expect(helper.valid_compare_preview_jwt?(expired_token, request_record)).to be false
    end

    it "returns false for an invalid sub" do
      second_request = FactoryBot.build(:request)

      expect(Rails.logger).to receive(:error).with(/Error JWT::InvalidSubError/)
      expect(helper.valid_compare_preview_jwt?(valid_token, second_request)).to be false
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
      expect(helper.valid_compare_preview_jwt?(diff_algorithm_token, request_record)).to be false
    end

    it "fails gracefully and returns false for a malformed token" do
      allow(JWT).to receive(:decode).and_raise(JWT::DecodeError)

      expect(Rails.logger).to receive(:error).with(/Error JWT::DecodeError/)
      expect(helper.valid_compare_preview_jwt?(valid_token, request_record)).to be false
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

  describe "#draft_origin_preview_url" do
    it "returns a draft origin URL with a JWT token" do
      token = helper.draft_origin_preview_jwt_token(request_record)
      allow(helper).to receive(:draft_origin_preview_jwt_token).and_return(token)

      url = helper.draft_origin_preview_url(request_record)

      expect(url).to eq("#{Plek.external_url_for('draft-origin')}/#{request_record.draft_slug}?token=#{token}")
    end

    it "generates a JWT with the edition's auth_bypass_id and content_id" do
      url = helper.draft_origin_preview_url(request_record)
      token = url.split("?token=").last

      decoded = JWT.decode(token, jwt_auth_secret, true, { algorithm: "HS256" })
      payload = decoded[0]

      expect(payload["sub"]).to eq(request_record.draft_auth_bypass_id)
      expect(payload["content_id"]).to eq(request_record.draft_content_id)
    end

    it "returns nil when draft_auth_bypass_id is blank" do
      request_record.draft_auth_bypass_id = nil
      expect(helper.draft_origin_preview_url(request_record)).to be_nil
    end

    it "returns nil when draft_content_id is blank" do
      request_record.draft_content_id = nil
      expect(helper.draft_origin_preview_url(request_record)).to be_nil
    end

    it "returns nil when draft_slug is blank" do
      request_record.draft_slug = nil
      expect(helper.draft_origin_preview_url(request_record)).to be_nil
    end

    it "generates a token that expires after 1 month" do
      freeze_time do
        url = helper.draft_origin_preview_url(request_record)
        token = url.split("?token=").last

        decoded = JWT.decode(token, jwt_auth_secret, true, { algorithm: "HS256" })
        payload = decoded[0]

        expect(payload["exp"]).to be(1.month.from_now.to_i)
      end
    end

    it "generates a token that cannot be decoded after expiry" do
      url = travel_to(2.months.ago) do
        helper.draft_origin_preview_url(request_record)
      end
      token = url.split("?token=").last

      expect {
        JWT.decode(token, jwt_auth_secret, true, { algorithm: "HS256" })
      }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
