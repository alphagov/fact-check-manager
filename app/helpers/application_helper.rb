module ApplicationHelper
  def zendesk_ticket_link(request)
    link_to(
      t("fact_check_submitted.zendesk_link"),
      "https://govuk.zendesk.com/tickets/#{request.zendesk_number}",
      class: "govuk-link--no-visited-state govuk-link",
      target: "_blank",
      rel: "noopener",
    )
  end
end
