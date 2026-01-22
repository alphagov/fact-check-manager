FactoryBot.define do
  factory :response do
    request
    user
    body { "MyText" }
  end
end
