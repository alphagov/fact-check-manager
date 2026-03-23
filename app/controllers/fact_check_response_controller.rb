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
    @errors = {}
    @session_data = session[:fact_check_response]&.deep_symbolize_keys
    response = Response.new(
      request_id: @session_data[:request_id],
      user: current_user,
      accepted: @session_data[:accepted],
      body: @session_data[:body],
    )

    unless response.save
      @errors = response.errors.full_messages
    end

    begin
      PublisherApiService.post_fact_check_response(response)
    rescue GdsApi::HTTPErrorResponse => e
      @errors = e.error_details
      response.delete
    end

    if @errors.present?
      render :fact_check_verify_response
    else
      session.delete(:fact_check_response)
      render :fact_check_submitted
    end
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
