class NotifyApiService
  # TODO: Update to real templates, currently points to a basic template for testing purposes
  NOTIFY_TEST_TEMPLATE_ID = "9bcb3051-9b6c-46f6-ad26-67f20d964016".freeze
  NO_REPLY_TO_EMAIL_ADDRESS = "no-reply-fact-check-request@dsit.gov.uk".freeze

  def self.resend_emails(_request_record)
    # TODO: Complete and test?
    true
  end

  def self.send_email_to_recipient(user, request, personalisation_hash)
    notify_response = Services.notify_api.send_email(
      email_address: user.email,
      template_id: NOTIFY_TEST_TEMPLATE_ID,
      email_reply_to_id: NO_REPLY_TO_EMAIL_ADDRESS,
      reference: "#{request.source_app}/#{request.source_id}",
      personalisation: personalisation_hash,
    )

    notify_response.instance_of?(Notifications::Client::ResponseNotification)
  end

  def self.send_emails_to_recipients(request)
    # TODO: iterate over request collaborations and use the above method to send email to each collaborator
  end
end
