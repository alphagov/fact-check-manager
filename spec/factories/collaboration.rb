FactoryBot.define do
  factory :collaboration do
    user
    request
    role { "recipient" }
  end
end
