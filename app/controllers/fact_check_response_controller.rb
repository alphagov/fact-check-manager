class FactCheckResponseController < ApplicationController
  before_action :load_flow_data

  # STEP 1 (GET)
  def respond_to_factcheck
    # Only reset if no flow exists
    @article_title = "Title"
    @draft_url = "/"
    @errors = {}

    if params[:from] == "edit_choice"
      @form_data = current_flow_data
    else
      reset_flow!
      @form_data = {}
    end

    render :fact_check_response
  end

  def verify_factcheck_response
    @form_data = permitted_params
    errors = validate(@form_data)

    if errors.any?
      @errors = errors
      @article_title = "Title"
      @draft_url = "/"
      render :fact_check_response
    else
      session[:fact_check_flow] = {
        data: @form_data.to_h,
        step: :validated,
      }

      render :confirm_response
    end
  end

  def confirm_response
    return redirect_to respond_path unless at_step?("validated")

    @form_data = current_flow_data
    render :confirm_response
  end

  def send_response
    return redirect_to respond_path unless at_step?("validated")

    @form_data = current_flow_data

    # TODO: API submission here

    session[:fact_check_flow][:step] = :completed

    render :fact_check_submitted
  end

  def fact_check_submitted
    return redirect_to respond_path unless at_step?("completed")

    reset_flow!
    render :fact_check_submitted
  end

  def wrong_entry_point
    reset_flow!
    redirect_to respond_path
  end

private

  def permitted_params
    params.fetch(:fact_check_response, {})
          .permit(:status, :details)
  end

  def validate(data)
    errors = {}
    errors[:status] = t("fact_check_response.selection_error") if data[:status].blank?

    if data[:status] == "incorrect" && data[:details].blank?
      errors[:details] = t("fact_check_response.factual_errors_empty_field")
    end

    errors
  end

  def flow_exists?
    session[:fact_check_flow].present?
  end

  def at_step?(expected_step)
    flow_exists? && session[:fact_check_flow]["step"] == expected_step
  end

  def current_flow_data
    flow_exists? ? session[:fact_check_flow]["data"] : {}
  end

  def reset_flow!
    session.delete(:fact_check_flow)
  end

  def load_flow_data
    @load_flow_data ||= current_flow_data
  end
end
