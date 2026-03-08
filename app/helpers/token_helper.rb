module TokenHelper
  def preview_factcheck_path
    path = "/preview/:id"

    path << "?token=#{jwt_token_factcheck}"

    path
  end

protected

  def jwt_token_factcheck
    payload = {
      "iat" => Time.zone.now.to_i,
      "exp" => 1.month.from_now.to_i,
    }
    JWT.encode(payload, jwt_auth_secret, "HS256")
  end

  def jwt_auth_secret
    Rails.application.config.jwt_auth_secret
  end
end
