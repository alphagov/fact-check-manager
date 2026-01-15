FactoryBot.define do
  factory :user do
    name { "Douglas Adams" }
    email { "d.adams@department.gov.uk" }
    uid { SecureRandom.uuid }
    organisation_slug { "another-gov-dept" }
    organisation_content_id { "another-gov-dept-id" }
    app_name { "fact_check_manager" }
    permissions { %w[test_1] }
  end
end
