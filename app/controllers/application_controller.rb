class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods
  include TokenHelper

  before_action :authenticate_user!, unless: :token_bypass?

  TOKEN_BYPASS_METHODS = %w[preview].freeze

  def hello_world
    render "hello_world"
  end

  def token_bypass?
    TOKEN_BYPASS_METHODS.include?(action_name) && valid_jwt?(preview_params[:token], preview_request)
  end

  def preview_request
    @preview_request ||= Request
      .where(source_app: preview_params[:source_app])
      .where(source_id: preview_params[:source_id])
      .last
  end

  def preview
    preview_request
    render "shareable_preview"
  end

  def preview_params
    params.permit(:source_app, :source_id, :token)
  end
end
