RSpec.configure do |config|
  %i[request system].each do |spec_type|
    config.before(:each, type: spec_type) do
      GDS::SSO.test_user = FactoryBot.create(:user)
    end

    config.after(:each, type: spec_type) do
      GDS::SSO.test_user = nil
    end
  end
end
