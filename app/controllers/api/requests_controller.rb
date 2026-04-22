module Api
  class RequestsController < Api::BaseController
    wrap_parameters include: Request.attribute_names + [:recipients]
    before_action :set_request_record, only: %i[update resend_emails]

    def create
      errors = validate_create_params
      return render json: { errors: errors }, status: :bad_request if errors.any?

      fact_check_request = Request.new(request_params.except(:recipients))

      request_params[:recipients].each do |email|
        user = User.find_or_create_by!(email: email)
        fact_check_request.collaborations.build(user: user, role: "fact_checker")
      end

      if fact_check_request.save
        render json: { id: fact_check_request.id, source_id: fact_check_request.source_id }, status: :created
      else
        render json: { errors: fact_check_request.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      if params.dig(:request, :current_content).present? && update_params[:current_content].blank?
        return render json: { errors: ["current_content must be a hash"] }, status: :bad_request
      end

      if @request_record.update(update_params)
        render json: { id: @request_record.id, source_id: @request_record.source_id, source_app: @request_record.source_app }, status: :ok
      else
        render json: { errors: @request_record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def resend_emails
      if NotifyService.resend_emails(@request_record)
        render json: { id: @request_record.id, source_id: @request_record.source_id, source_app: @request_record.source_app }, status: :ok
      else
        render json: { errors: @request_record.errors.full_messages }, status: :unprocessable_entity
      end
    end

  private

    def request_params
      params.require(:request).permit(
        :source_app,
        :source_id,
        :source_url, # optional
        :source_title, # optional
        :requester_name,
        :requester_email,
        :deadline,
        :draft_content_id, # optional
        :draft_auth_bypass_id, # optional
        :draft_slug, # optional
        recipients: [],
        # dynamic hash fields at the end
        current_content: {},
        previous_content: {}, # optional
      )
    end

    def update_params
      params.require(:request).permit(
        :source_title, # optional
        :draft_auth_bypass_id, # optional
        :draft_slug, # optional
        current_content: {},
      )
    end

    def validate_create_params
      errors = []

      errors << "At least one recipient email is required" if request_params[:recipients].blank?

      %i[current_content previous_content].each do |content_hash|
        if params.dig(:request, content_hash).present? && request_params[content_hash].blank?
          errors << "#{content_hash} must be a hash"
        end
      end

      errors
    end

    def set_request_record
      @request_record = Request.most_recent_for_source(source_app: params[:source_app], source_id: params[:source_id])

      unless @request_record
        render json: { errors: ["Request with ID #{params[:source_id]} not found for app #{params[:source_app]}"] }, status: :not_found
      end
    end
  end
end
