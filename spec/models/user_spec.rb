require "rails_helper"
require "gds-sso/lint/user_spec"

RSpec.describe User, type: :model do
  # Linting test verifies that User model is compatible with GDS:SSO::User:
  it_behaves_like "a gds-sso user class"

  describe "associations" do
    it "can access requests through collaborations" do
      user = create(:user)
      request = create(:request)

      create(:collaboration, user: user, request: request)

      expect(user.requests).to include(request)
    end
  end
end
