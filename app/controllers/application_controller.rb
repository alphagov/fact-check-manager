class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "design_system"

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!
end
