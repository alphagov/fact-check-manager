module ApiErrorHandlerConcern
  extend ActiveSupport::Concern

  included do
    rescue_from "Notifications::Client::RequestError", with: :notify_request_error_handler
    rescue_from "Notifications::Client::BadRequestError", with: :handle_notify_bad_request
  end

  def notify_request_error_handler(exception)
    Rails.logger.info("Error: #{exception.code}, #{exception.message}")
    render json: { errors: { notify_error: exception.message, error_code: exception.code } }, status: :bad_gateway
  end

  def handle_notify_bad_request(exception)
    not_prod = %w[integration staging].include?(ENV.fetch("GOVUK_ENVIRONMENT", nil))
    if not_prod && exception.message =~ /team-only API key/
      team_only_error_message = "One or more recipients not in GOV.UK Notify team. This error will not occur in Production."
      Rails.logger.info("Error: #{exception.code}, #{team_only_error_message}")
      render json: {
        errors: {
          notify_error: team_only_error_message,
          error_code: exception.code,
        },
      }, status: :bad_gateway
    else
      notify_request_error_handler(exception)
    end
  end
end
