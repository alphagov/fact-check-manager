FactoryBot.define do
  factory :request do
    transient do
      collaborator { FactoryBot.create(:user) }
    end

    source_id { SecureRandom.uuid }
    source_app { "publisher" }
    status { "new" }
    requester_name { "Malcolm Tucker" }
    requester_email { "m.tucker@gov.uk" }
    auth_bypass_id { SecureRandom.uuid }
    draft_content_id { SecureRandom.uuid }
    draft_auth_bypass_id { SecureRandom.uuid }
    draft_slug { "test-slug" }
    current_content do
      { "id_value" => {
        "heading" => "test_heading", "body" => "<p>Many lines of data for the content. Many changes that need fact checking</p>"
      } }
    end
    deadline { Time.zone.now + 1.week }

    trait :with_more_complex_content_data do
      multi_part_previous_content = { "id_1" =>
                                      {
                                        "heading" => "How to claim for intergalactic travel expenses",
                                        "body" => "<p>If you or your partner is travelling abroad for more than 7 months, you may be able to claim for expenses.</p>",
                                      },
                                      "id_2" =>
                                      {
                                        "heading" => "How to claim for lost luncheon meat",
                                        "body" => "<p>If you have lost your luncheon meat, please inform your local sandwich maker.</p>",
                                      } }
      multi_part_current_content = { "id_1" =>
                                      {
                                        "heading" => "How to claim for intergalactic travel costs",
                                        "body" => "<p>If you or your partner is travelling abroad for more than 2 weeks, you may be able to claim for expenses.</p>",
                                      },
                                     "id_2" =>
                                      {
                                        "heading" => "How to claim for lost luncheon meat",
                                        "body" => "<p>If you have lost your luncheon meat, please inform your local sandwich maker immediately, or find the nearest cake dispenser.</p>",
                                      } }
      previous_content { multi_part_previous_content }
      current_content { multi_part_current_content }
    end

    trait :with_collaborator do
      after(:build) do |request, evaluator|
        FactoryBot.create(:collaboration,
                          user: evaluator.collaborator,
                          request: request)
      end
    end
  end
end
