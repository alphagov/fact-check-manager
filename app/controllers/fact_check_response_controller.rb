class FactCheckResponseController < ApplicationController
  before_action :set_request, :check_permissions, only: %i[respond_to_fact_check validate_fact_check_response send_response]

  def respond_to_fact_check
    session.delete(:fact_check_response) unless params[:back]
    @errors = {}
    @form_data = session.fetch(:fact_check_response, {}).with_indifferent_access

    render :fact_check_response
  end

  def validate_fact_check_response
    @form_data = permitted_params
    @errors = validate_form_data(@form_data)

    if @errors.any?
      render :fact_check_response
    else
      session[:fact_check_response] = @form_data
      render :fact_check_verify_response
    end
  end

  def send_response
    @errors = []
    @form_data = permitted_params

    response = Response.new(
      request: @request,
      user: current_user,
      accepted: @form_data[:accepted],
      body: @form_data[:body],
    )

    ActiveRecord::Base.transaction do
      if response.save
        begin
          PublisherApiService.post_fact_check_response(response)
        rescue GdsApi::HTTPErrorResponse
          @errors << t("fact_check_verification.api_submission_error")
          raise ActiveRecord::Rollback
        end
      else
        @errors = response.errors.full_messages
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

  def check_permissions
    return if current_user.govuk_admin? || @request.users.include?(current_user)

    flash[:danger] = "You do not have permission to see this page."
    redirect_to compare_path(@request.source_app, @request.source_id)
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
end
