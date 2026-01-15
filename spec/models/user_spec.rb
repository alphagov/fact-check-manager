require "rails_helper"
require "gds-sso/lint/user_spec"

RSpec.describe User, type: :model do
  # Linting test verifies that User model is compatible with GDS:SSO::User:
  it_behaves_like "a gds-sso user class"
end
