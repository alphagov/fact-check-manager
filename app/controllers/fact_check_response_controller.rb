class FactCheckResponseController < ApplicationController
  include AuthenticationHelper

  before_action :set_request, :check_access, only: %i[respond_to_fact_check validate_fact_check_response send_response change_answers]
  before_action :check_already_responded, only: %i[respond_to_fact_check validate_fact_check_response send_response change_answers]

  def respond_to_fact_check
    @errors = {}
    @form_data = {}

    render :fact_check_response
  end

  def change_answers
    @errors = {}
    @form_data = permitted_params
    render :fact_check_response
  end

  def validate_fact_check_response
    @form_data = permitted_params
    @errors = validate_form_data(@form_data)

    if @errors.any?
      render :fact_check_response
    else
      render :fact_check_verify_response
    end
  end

  def send_response
    @errors = []
    @form_data = permitted_params

    @response = Response.new(
      request: @request,
      user: current_user,
      accepted: @form_data[:accepted],
      body: @form_data[:body],
    )

    ActiveRecord::Base.transaction do
      if @response.save
        begin
          PublisherApiService.post_fact_check_response(@response)
        rescue GdsApi::HTTPErrorResponse => e
          if e.error_details&.empty? || e.error_details.is_a?(String)
            @errors << t("fact_check_verification.api_submission_error")
          else
            received_errors = e.error_details&.dig("errors")
            @errors << if state_error_present?(received_errors)
                         t("fact_check_verification.api_submission_request_cancelled")
                       else
                         # Error is probably a hash (Model error) but not a state error
                         # We may deal with more error types here in future
                         t("fact_check_verification.api_submission_error")
                       end
          end

          raise ActiveRecord::Rollback
        end

        begin
          personalisation_hash = build_personalisation_hash(@response)
          if @response.accepted
            NotifyApiService.send_response_accepted_email(@response, personalisation_hash)
          else
            NotifyApiService.send_response_rejected_email(@response, personalisation_hash)
          end
        rescue Notifications::Client::RequestError
          # We don't roll back the DB or Publisher if the confirmation email fails, but we do display an error
          @errors << t("fact_check_verification.notify_submission_error")
        end
      else
        @errors = @response.errors.full_messages
      end
    end

    if @errors.present?
      render :fact_check_verify_response
    else
      session.delete(:fact_check_response)
      render :fact_check_submitted
    end
  end

private

  def set_request
    @request = Request.most_recent_for_source(source_app: params[:source_app], source_id: params[:source_id])
    raise ActiveRecord::RecordNotFound, "No request found" unless @request
  end

  def check_access
    check_permissions(current_user, @request)
  end

  def check_already_responded
    return if @request.response.blank?

    render "application/fact_check_already_submitted"
  end

  def permitted_params
    params.require(:fact_check_response)
          .permit(:accepted, :body)
  end

  def validate_form_data(data)
    errors = {}
    errors[:accepted] = t("fact_check_response.selection_error") if data[:accepted].blank?

    if data[:accepted] == "false" && data[:body].blank?
      errors[:body] = t("fact_check_response.factual_errors_empty_field")
    end

    errors
  end

  def build_personalisation_hash(response)
    {
      content_title: response.request.source_title,
      responder_name: response.user.name,
    }.tap do |hash|
      unless response.accepted
        formatted_body = response.body.lines(chomp: true).map { |line| "^#{line}" }.join("\n")
        hash[:reason_for_rejection] = formatted_body
      end
    end
  end

  def state_error_present?(errors)
    Array.wrap(errors).any? do |error|
      error.is_a?(Hash) && (error.key?("state") || error.key?(:state))
    end
  end
end
