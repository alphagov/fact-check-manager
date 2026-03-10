class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods
  include TokenHelper

  before_action :authenticate_user!

  def preview
    @request = Request
      .where(source_app: preview_params[:source_app])
      .where(source_id: preview_params[:source_id])
      .first
    render "shareable_preview"
  end

  def preview_params
    params.permit(:source_app, :source_id)
  end
end
