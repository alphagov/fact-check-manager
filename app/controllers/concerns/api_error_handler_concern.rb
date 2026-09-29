module ApiErrorHandlerConcern
  extend ActiveSupport::Concern

  included do
    rescue_from "Notifications::Client::RequestError", with: :notify_request_error_handler
    rescue_from "Notifications::Client::BadRequestError", with: :handle_notify_bad_request
  end

  def notify_request_error_handler(exception)
    Rails.logger.error("Error: #{exception.code}, #{exception.message}")
    GovukError.notify(exception, extra: notify_error_context)
    render json: { errors: { notify_error: exception.message, error_code: exception.code } }, status: :bad_gateway
  end

  def handle_notify_bad_request(exception)
    not_prod = %w[integration staging].include?(ENV.fetch("GOVUK_ENVIRONMENT", nil))
    if not_prod && exception.message =~ /team-only API key/
      # Expected outside production, so logged but not reported to Sentry
      team_only_error_message = "One or more recipients not in GOV.UK Notify team. This error will not occur in Production."
      Rails.logger.error("Error: #{exception.code}, #{team_only_error_message}")
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

private

  def notify_error_context
    {
      source_app: params[:source_app] || params.dig(:request, :source_app),
      source_id: params[:source_id] || params.dig(:request, :source_id),
      request_id: request.request_id,
    }
  end
end
