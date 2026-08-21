require "gds-sso/user"
class User < ApplicationRecord
  include GDS::SSO::User

  has_many :collaborations, dependent: :destroy
  has_many :requests, through: :collaborations
  has_many :responses

  normalizes :email, with: ->(email) { email.strip.downcase }

  def signin?
    permissions.include?("signin")
  end

  def govuk_admin?
    permissions.include?("govuk_admin")
  end
end
