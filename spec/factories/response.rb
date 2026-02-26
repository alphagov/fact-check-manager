FactoryBot.define do
  factory :response do
    request
    user
    accepted { true }
    body { "MyText" }
  end
end
