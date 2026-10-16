class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!

  helper_method :accessibility_statement_link

private

  def accessibility_statement_link
    accessibility_statement_path
  end
end
