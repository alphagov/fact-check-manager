Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response

  root to: "application#hello_world"

  get "compare", to: "fact_check_comparison#compare"

  namespace :api do
    patch "requests/:source_app/:source_id", to: "requests#update", as: :update_request
    resources :requests, only: %i[create]
  end
end
