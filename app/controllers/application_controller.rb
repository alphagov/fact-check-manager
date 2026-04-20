class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods
  include TokenHelper

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
end
