RSpec.configure do |config|
  %i[request system].each do |spec_type|
    config.before(:each, type: spec_type) do
      GDS::SSO.test_user = FactoryBot.create(:user)
    end

    config.after(:each, type: spec_type) do
      GDS::SSO.test_user = nil
    end
  end

  # API specs call the API as Publisher's API user, which has internal_app
  config.before(:each, type: :request, file_path: %r{spec/requests/api/requests/}) do
    GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin internal_app])
  end
end
