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

    it "can access a user's associated responses" do
      user = create(:user)
      response = create(:response, request: create(:request), user: user)

      expect(user.responses).to include(response)
    end

    context "deleting a user" do
      it "causes the associated collaborations to be destroyed" do
        user = create(:user)
        request = create(:request)
        create(:collaboration, user: user, request: request)

        expect {
          user.destroy
        }.to change { Collaboration.count }.by(-1)
                                           .and change { Request.count }.by(0)
      end
    end
  end
end
