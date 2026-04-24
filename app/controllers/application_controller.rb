class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods
  include TokenHelper

  before_action :authenticate_user!
  def token_bypass?
    current_request = Request.most_recent_for_source(source_app: bypass_params[:source_app], source_id: bypass_params[:source_id])
    return unless current_request

    valid_compare_preview_jwt?(bypass_params[:token], current_request)
  end

  def bypass_params
    params.permit(:source_app, :source_id, :token)
  end
end
