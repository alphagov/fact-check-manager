class NotifyApiService
  # TODO: Update to real templates, currently points to a basic template for testing purposes
  NOTIFY_TEST_TEMPLATE_ID = "9bcb3051-9b6c-46f6-ad26-67f20d964016".freeze

  def self.send_new_fact_check_request_email(user, request, personalisation_hash)
    template_id = ENV.fetch("GOVUK_NOTIFY_NEW_FACT_CHECK_REQUEST_TEMPLATE_ID", nil)

    send_email_to_recipient(user, request, template_id, personalisation_hash)
  end

  def self.resend_emails(_request_record)
    # TODO: Complete and test?
    true
  end

  def self.send_email_to_recipient(user, request, template_id, personalisation_hash)
    # We only have one reply to email, which is default and so it's not necessary to specify here
    notify_response = Services.notify_api.send_email(
      email_address: user.email,
      template_id: template_id,
      reference: "#{request.source_app}/#{request.source_id}",
      personalisation: personalisation_hash,
    )

    notify_response.instance_of?(Notifications::Client::ResponseNotification)
  end
end
