FactoryBot.define do
  factory :user do
    email { "d.adams@department.gov.uk" }

    trait :full do
      name { "Douglas Adams" }
      uid { SecureRandom.uuid }
      organisation_slug { "another-gov-dept" }
      organisation_content_id { "another-gov-dept-id" }
      app_name { "fact_check_manager" }
      permissions { %w[test_1] }
    end
  end
end
