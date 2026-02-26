require "gds_api/base"

class GdsApi::Publisher < GdsApi::Base
  # Post a fact check response back to Publisher
  #
  # Keyword Arguments:
  # @param [uuid] edition_id UUID for the edition
  # @param [string] responder_name First and Last name of the user responding to the fact check
  # @param [boolean] accepted Whether the changes being fact checked have been accepted or not
  # @option [string] comment If accepted is false, provide a comment explaining why. Mandatory if accepted is false, optional if not
  #
  # @return [GdsApi::Response] Basic response with code

  def post_fact_check_response(edition_id:, responder_name:, accepted:, comment: nil)
    post_json(
      "#{endpoint}/api/fact-check-response",
      edition_id:,
      responder_name:,
      accepted:,
      comment:,
    )
  end
end
