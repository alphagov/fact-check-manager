FactoryBot.define do
  factory :request do
    source_id { SecureRandom.uuid }
    source_app { "publisher" }
    requester_name { "Malcolm Tucker" }
    requester_email { "m.tucker@gov.uk" }
    current_content do
      {
        "body":
          "Many lines of data for the content. Many changes that need fact checking",
      }
    end
    previous_content { {} }
    deadline { Time.zone.now + 1.week }

    trait :with_more_complex_content_data do
      multi_part_previous_content = { heading: "How to claim for intergalactic travel expenses",
                                      body: "If you or your partner is travelling abroad for more than 7 months, you may be able to claim for expenses." }
      multi_part_current_content = { heading: "How to claim for Inter-galactic Travel Expenses",
                                     body: "If you or your partner are travelling abroad for more than 8 months, you may be able to claim for expenses." }
      previous_content { multi_part_previous_content }
      current_content { multi_part_current_content }
    end
  end
end
