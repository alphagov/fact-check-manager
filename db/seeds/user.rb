gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"

  User.find_or_create_by(name: 'Test User') do |user|
    user.name = "Test user"
    user.email = "test.user@gov.uk"
    user.uid = SecureRandom.uuid
    user.permissions = %w[test_1, test_2]
    user.organisation_content_id = gds_organisation_id
end