require "rails_helper"

RSpec.describe "FactCheckResponse", type: :request do
  before do
    create(:user)
  end

  describe "GET /respond" do
    it "returns 404 when no request exists for the given source_app and source_id" do
      get respond_path(source_app: "invalid", source_id: "invalid")

      expect(response).to have_http_status(:not_found)
    end
  end
end
