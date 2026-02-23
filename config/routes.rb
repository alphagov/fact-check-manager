Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response

  root to: "application#hello_world"

  get "compare", to: "fact_check_comparison#compare"

  # TODO: Wrap in a resources block
  # See: https://github.com/alphagov/fact-check-manager/pull/33#discussion_r2905663106
  get  "respond", to: "fact_check_response#respond_to_fact_check"
  post "respond", to: "fact_check_response#verify_fact_check_response"

  get  "confirm_response", to: redirect("/respond")
  post "confirm_response", to: "fact_check_response#send_response"

  get  "fact_check_submitted", to: redirect("/respond")
  post "fact_check_submitted", to: "fact_check_response#fact_check_submitted"

  namespace :api do
    resources :requests, only: [:create]
  end
end
