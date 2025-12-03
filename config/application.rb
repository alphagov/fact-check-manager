require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

require "open-uri"
require "builder"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FactCheckManager
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.version = "1.0"

    # Set asset path to be application specific so that we can put all GOV.UK
    # assets into an S3 bucket and distinguish app by path.
    config.assets.prefix = "/assets/fact-check-manager"

    # allow overriding the asset host with an environment variable, useful for
    # when router is proxying to this app but asset proxying isn't set up.
    config.asset_host = ENV.fetch("ASSET_HOST", nil)

    # config.action_mailer.notify_settings = {
    #   api_key: ENV["GOVUK_NOTIFY_API_KEY"] || "fake-test-api-key",
    # }

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default set by govuk_app_config is London.
    config.govuk_time_zone = "London"
  end
end
