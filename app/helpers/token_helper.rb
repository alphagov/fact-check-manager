module TokenHelper
  def generate_preview_link(request)
    path = requests_preview_path(request.source_app, request.source_id)
    path << "?token=#{jwt_token(request)}"

    path
  end

  def valid_jwt?(jwt_token, request)
    decoded_token = JWT.decode(jwt_token, jwt_auth_secret)
    token_matches_request?(decoded_token, request)
  rescue JWT::VerificationError, JWT::Base64DecodeError, JWT::ExpiredSignature, JWT::DecodeError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    false
  end

protected

  def jwt_token(request)
    payload = {
      "source_app" => request.source_app,
      "source_id" => request.source_id,
      "auth_bypass_id" => request.auth_bypass_id,
      "iat" => Time.zone.now.to_i,
      "exp" => 1.month.from_now.to_i,
    }
    JWT.encode(payload, jwt_auth_secret, "HS256")
  end

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end

  def token_matches_request?(jwt_token, request)
    jwt_token[0].slice("source_app", "source_id", "auth_bypass_id") == request.slice(:source_app, :source_id, :auth_bypass_id)
  end
end
