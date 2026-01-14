require "gds-sso/user"
class User < ApplicationRecord
  include GDS::SSO::User

  has_many :collaborations, dependent: :destroy
  has_many :requests, through: :collaborations
end
