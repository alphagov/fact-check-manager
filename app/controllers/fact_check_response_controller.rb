class FactCheckResponseController < ApplicationController
  include AuthenticationHelper

  before_action :set_request, :check_access, only: %i[respond_to_fact_check validate_fact_check_response send_response]
  before_action :check_already_responded, only: %i[respond_to_fact_check validate_fact_check_response send_response]

  def respond_to_fact_check
    @errors = {}
    @form_data = permitted_params

    render :fact_check_response
  end

  def validate_fact_check_response
    @form_data = permitted_params
    @validation_response = Response.new(
      request: @request,
      user: current_user,
      accepted: @form_data[:accepted],
      body: @form_data[:body],
    )

    @validation_response.valid?
    @errors = @validation_response.errors

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
        rescue GdsApi::BaseError => e
          GovukError.notify(
            "Failed to send fact check response to Publisher",
            extra: error_context.merge(
              error_class: e.class.name,
              error_message: e.message,
              status_code: e.try(:code),
            ),
          )
          @errors << publisher_error_message(e)

          raise ActiveRecord::Rollback
        end

        begin
          personalisation_hash = build_personalisation_hash(@response)
          if @response.accepted
            NotifyApiService.send_response_accepted_email(@response, personalisation_hash)
          else
            NotifyApiService.send_response_rejected_email(@response, personalisation_hash)
          end
        rescue StandardError => e
          # Publisher has already accepted the response, so we don't roll back the DB if the confirmation
          # email fails for any reason, including network errors, but we do report it and display an error
          GovukError.notify(e, extra: error_context)
          @errors << t("fact_check_verification.notify_submission_error")
        end
      else
        @errors = @response.errors.full_messages
      end
    end

    if @errors.present?
      render :fact_check_verify_response
    else
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
    return {} if params[:fact_check_response].blank?

    params.require(:fact_check_response)
          .permit(:accepted, :body)
  end

  def build_personalisation_hash(response)
    {
      content_title: response.request.source_title,
      responder_name: response.user.name,
      non_tokenised_link: generate_compare_link(response.request),
    }.tap do |hash|
      unless response.accepted
        formatted_body = response.body.lines(chomp: true).map { |line| "^#{line}" }.join("\n")
        hash[:reason_for_rejection] = formatted_body
      end
    end
  end

  def error_context
    {
      source_app: @request.source_app,
      source_id: @request.source_id,
      request_id: request.request_id,
    }
  end

  def publisher_error_message(error)
    # Only HTTP errors carry details; timeouts and connection failures do not
    error_details = error.try(:error_details)

    if error_details.is_a?(Hash) && state_error_present?(error_details["errors"])
      t("fact_check_verification.api_submission_request_cancelled")
    else
      t("fact_check_verification.api_submission_error")
    end
  end

  def state_error_present?(errors)
    Array.wrap(errors).any? do |error|
      error.is_a?(Hash) && (error.key?("state") || error.key?(:state))
    end
  end
end
