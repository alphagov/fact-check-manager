class FactCheckResponseController < ApplicationController
  def respond_to_fact_check
    @errors = {}
    @session_data = session[:fact_check_response]&.deep_symbolize_keys

    render :fact_check_response
  end

  def validate_fact_check_response
    @session_data = session[:fact_check_response]&.deep_symbolize_keys
    @session_data[:accepted] = params[:fact_check_response][:accepted]
    @session_data[:body] = params[:fact_check_response][:body]
    @errors = validate(@session_data)

    if @errors.any?
      @article_title = @session_data[:article_title]
      @request_id = @session_data[:request_id]
      render :fact_check_response
    else
      session[:fact_check_response] = @session_data
      render :fact_check_verify_response
    end
  end

  def send_response
      session.delete(:fact_check_response)
      render :fact_check_submitted
  end

private

  def permitted_params
    params.fetch(:fact_check_response, {})
          .permit(:article_title, :request_id, :accepted, :body)
  end

  def session_data
    session[:fact_check_response]&.deep_symbolize_keys
  end

  def validate(data)
    errors = {}
    errors[:accepted] = t("fact_check_response.selection_error") if data[:accepted].blank?

    if data[:accepted] == "incorrect" && data[:body].blank?
      errors[:body] = t("fact_check_response.factual_errors_empty_field")
    end

    errors
  end
end
