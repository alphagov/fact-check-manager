module Api
  class RequestsController < ApplicationController
    # TODO: Implement authentication later
    # before_action :authenticate_publisher!

    def create
      fact_check_request = Request.new(request_params.except(:recipients))

      if request_params[:recipients].present?
        request_params[:recipients].each do |email|
          user = User.find_or_create_by!(email: email) do |u|
            u.name = email.split("@").first
            u.uid = SecureRandom.uuid
          end

          fact_check_request.collaborations.build(user: user, role: "fact_checker")
        end
      end

      if fact_check_request.save
        render json: { id: fact_check_request.id, edition_id: fact_check_request.edition_id }, status: :created
      else
        render json: { errors: fact_check_request.errors.full_messages }, status: :bad_request
      end
    end

  private

    def request_params
      params.require(:request).permit(
        :edition_id,
        :requester_name,
        :requester_email,
        :current_content,
        :previous_published_edition,
        :deadline,
        recipients: [],
      )
    end
  end
end
