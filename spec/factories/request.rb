FactoryBot.define do
  factory :request do
    source_id { SecureRandom.uuid }
    source_app { "publisher" }
    requester_name { "Malcolm Tucker" }
    requester_email { "m.tucker@gov.uk" }
    current_content { { "body" => "<HTML> Changes go here <HTML>" } }
    deadline { Time.zone.now + 1.week }
  end
end
