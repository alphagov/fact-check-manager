module Api
  class RequestsController < Api::BaseController
    wrap_parameters include: Request.attribute_names + [:recipients]

    def create
      if request_params[:recipients].blank?
        return render json: { errors: ["At least one recipient email is required"] }, status: :bad_request
      end

      fact_check_request = Request.new(request_params.except(:recipients))

      request_params[:recipients].each do |email|
        user = User.find_or_create_by!(email: email) do |u|
          u.name = email.split("@").first
          u.uid = SecureRandom.uuid
        end

        fact_check_request.collaborations.build(user: user, role: "fact_checker")
      end

      if fact_check_request.save
        render json: { id: fact_check_request.id, source_id: fact_check_request.source_id }, status: :created
      else
        render json: { errors: fact_check_request.errors.full_messages }, status: :bad_request
      end
    end

    def update
      request_record = Request.find_by(source_app: params[:source_app], source_id: params[:source_id])

      if request_record.nil?
        return render json: { errors: "Request with ID #{params[:source_id]} not found for app #{params[:source_app]}" }, status: :bad_request
      end

      if request_record.update(update_params)
        render json: { id: request_record.id, source_id: request_record.source_id, source_app: request_record.source_app }, status: :ok
      else
        render json: { errors: request_record.errors.full_messages }, status: :unprocessable_entity
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
        :current_content,
        :previous_content, # optional
        :deadline, # optional
        recipients: [],
        # dynamic hash fields at the end
        current_content: {},
        previous_content: {}, # optional
      )
    end

    def update_params
      params.require(:request).permit(
        :current_content,
        :source_title, # optional
      )
    end
  end
end
