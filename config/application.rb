require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

require "open-uri"
require "builder"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FactCheckManager
  class Application < Rails::Application

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    # Due to how we initialize state_count_reporter we need to disable a new
    # optimisation put in place in Rails 7.1.
    # See: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#autoloaded-paths-are-no-longer-in-$load-path
    config.add_autoload_paths_to_load_path = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

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
