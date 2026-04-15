module TokenHelper
  def generate_preview_link(request)
    path = preview_path(request.source_app, request.source_id)
    path << "?token=#{jwt_token(request)}"

    path
  end

  def draft_origin_preview_url(request)
    return nil if request.draft_auth_bypass_id.blank? || request.draft_content_id.blank? || request.draft_slug.blank?

    "#{Plek.external_url_for('draft-origin')}/#{request.draft_slug}?token=#{draft_origin_preview_jwt_token(request)}"
  end

  def valid_jwt?(jwt_token, request)
    decoded_token = JWT.decode(jwt_token, jwt_auth_secret, true, {
      verify_expiration: true,
      verify_sub: true,
      sub: request.auth_bypass_id,
      algorithm: "HS256",
    })
    token_matches_request?(decoded_token, request)
  rescue JWT::VerificationError, JWT::ExpiredSignature, JWT::InvalidSubError, JWT::DecodeError, JWT::Base64DecodeError, JWT::IncorrectAlgorithm => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    false
  end

protected

  def draft_origin_preview_jwt_token(request)
    payload = {
      "sub" => request.draft_auth_bypass_id,
      "content_id" => request.draft_content_id,
      "iat" => Time.zone.now.to_i,
      "exp" => 1.month.from_now.to_i,
    }
    JWT.encode(payload, jwt_auth_secret, "HS256")
  end

  def jwt_token(request)
    payload = {
      "source_app" => request.source_app,
      "source_id" => request.source_id,
      "sub" => request.auth_bypass_id,
      "iat" => Time.zone.now.to_i,
      "exp" => 1.month.from_now.to_i,
    }
    JWT.encode(payload, jwt_auth_secret, "HS256")
  end

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def token_matches_request?(decoded_jwt_token, request)
    decoded_jwt_token[0].slice("source_app", "source_id") == request.slice(:source_app, :source_id).stringify_keys
  end
end
