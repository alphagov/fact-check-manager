class FactCheckResponseController < ApplicationController
  before_action :initialize_form, only: [:respond_to_factcheck]

  def respond_to_factcheck
    @article_title = "Title"
    @draft_url = "/"
    @errors = {}
    @form_data = stored_form_data
    render "fact_check_response"
  end

  def verify_factcheck_response
    @form_data = stored_form_data

    errors = {}
    errors[:status] = t("fact_check_response.selection_error") if @form_data[:status].blank?
    if @form_data[:status] == "incorrect" && @form_data[:details].blank?
      errors[:details] = t("fact_check_response.factual_errors_empty_field")
    end

    if errors.any?
      @errors = errors
      render :fact_check_response, status: :unprocessable_entity
    else
      confirm_response
    end
  end

  def confirm_response
    @form_data = stored_form_data
    render "confirm_response"
  end

  def send_response
    # Empty op for API work
    render "fact_check_submitted"
  end

  def initialize_form
    @form_data = stored_form_data
  end

  def stored_form_data
    params.fetch(:fact_check_response, {})
          .permit(:status, :details)
  end
end
