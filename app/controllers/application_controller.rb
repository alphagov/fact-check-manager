require "notifications/client"

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods
  include TokenHelper

  rescue_from Notifications::Client::RequestError, with: :notify_request_error_handler
  rescue_from Notifications::Client::BadRequestError, with: :notify_bad_request_error_handler

  before_action :authenticate_user!, unless: :token_bypass?

  TOKEN_BYPASS_METHODS = %w[preview].freeze

  def token_bypass?
    TOKEN_BYPASS_METHODS.include?(action_name) && valid_compare_preview_jwt?(preview_params[:token], set_preview_request)
  end

  def set_preview_request
    @set_preview_request ||= Request.most_recent_for_source(source_app: preview_params[:source_app], source_id: preview_params[:source_id])
  end

  def preview
    set_preview_request
    render "shareable_preview"
  end

  def preview_params
    params.permit(:source_app, :source_id, :token)
  end

  def notify_request_error_handler(exception)
    Rails.logger.info("Error: #{exception.code}, #{exception.message}")
    render json: { errors: { notify_error: exception.message, error_code: exception.code } }, status: :bad_gateway
  end

  def notify_bad_request_error_handler(exception)
    not_prod = %w[integration staging].include?(ENV.fetch("GOVUK_ENVIRONMENT"))
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
