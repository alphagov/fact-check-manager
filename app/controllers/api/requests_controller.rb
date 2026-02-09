module Api
  class RequestsController < Api::BaseController
    def create
      if recipients.blank?
        return render json: { errors: ["At least one recipient email is required"] }, status: :bad_request
      end

      fact_check_request = Request.new(request_params.except(:recipients))

      recipients.each do |email|
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
      )
    end

    def recipients
      params.fetch(:recipients, [])
    end
  end
end
