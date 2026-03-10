Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response

  root to: proc { raise ActionController::RoutingError, "Not found" }

  scope "requests" do
    scope ":source_app" do
      scope ":source_id" do
        get "compare", to: "fact_check_comparison#compare"
        get  "respond", to: "fact_check_response#respond_to_fact_check"
        post "verify-response", to: "fact_check_response#validate_fact_check_response"
        post "confirm-response", to: "fact_check_response#send_response"
      end
    end
  end

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

  namespace :requests do
    scope ":source_app" do
      scope ":source_id" do
        get "/preview", to: "/application#preview"
      end
    end
  end
end
