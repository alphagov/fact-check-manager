require "gds-sso/user"

class User < ApplicationRecord
  include GDS::SSO::User


end
