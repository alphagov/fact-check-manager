Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response

  root to: "application#hello_world"

  get "compare", to: "fact_check_comparison#compare"

  # TODO: Wrap in a resources block
  # See: https://github.com/alphagov/fact-check-manager/pull/33#discussion_r2905663106
  get  "respond", to: "fact_check_response#respond_to_fact_check"
  post "respond", to: "fact_check_response#verify_fact_check_response"
  post "confirm-response", to: "fact_check_response#send_response"
  post "fact-check-submitted", to: "fact_check_response#fact_check_submitted"

  namespace :api do
    resources :requests, only: %i[create]

    namespace :requests do
      scope ":source_app" do
        scope ":source_id" do
          post "/resend-emails", to: "resend_emails"
          patch "", to: "/api/requests#update", as: :update_request
        end
      end
    end
  end
end
