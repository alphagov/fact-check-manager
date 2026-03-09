class FactCheckResponseController < ApplicationController
  def respond_to_fact_check
    session.delete(:fact_check_response) unless params[:back]
    @article_title = "Title"
    @errors = {}
    @form_data = session[:fact_check_response] || {}

    render :fact_check_response
  end

  def verify_fact_check_response
    @form_data = permitted_params
    @errors = validate(@form_data)

    if @errors.any?
      @article_title = "Title"
      render :fact_check_response
    else
      session[:fact_check_response] = @form_data
      confirm_response
    end
  end

  def confirm_response
    @errors = {}
    render :confirm_response
  end

  def send_response
    # TODO: API submission here

    fact_check_submitted
  end

  def fact_check_submitted
    render :fact_check_submitted
  end

private

  def permitted_params
    params.fetch(:fact_check_response, {})
          .permit(:page_title, :page_id, :status, :details)
  end

  def validate(data)
    errors = {}
    errors[:status] = t("fact_check_response.selection_error") if data[:status].blank?

    if data[:status] == "incorrect" && data[:details].blank?
      errors[:details] = t("fact_check_response.factual_errors_empty_field")
    end

    errors
  end
end
