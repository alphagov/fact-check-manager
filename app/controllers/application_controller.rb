class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  layout "application"

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!

  def hello_world
    render "hello_world"
  end
end
