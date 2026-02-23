Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response

  root to: "application#hello_world"

  get "compare", to: "fact_check_comparison#compare"

  get "respond", to: "fact_check_response#respond_to_factcheck"
  post "respond", to: "fact_check_response#verify_factcheck_response"

  get "confirm_response", to: "fact_check_response#respond_to_factcheck"
  post "confirm_response", to: "fact_check_response#send_response"

  get "fact_check_submitted", to: "fact_check_response#respond_to_factcheck"

  namespace :api do
    resources :requests, only: [:create]
  end
end
