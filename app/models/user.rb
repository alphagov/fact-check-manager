require "gds-sso/user"
class User < ApplicationRecord
  include GDS::SSO::User

  has_many :collaborations, dependent: :destroy
  has_many :requests, through: :collaborations
  has_many :responses

  before_save :downcase_email

  def signin?
    permissions.include?("signin")
  end

  def govuk_admin?
    permissions.include?("govuk_admin")
  end

  def downcase_email
    unless email.nil?
      email.downcase!
    end
  end
end
