source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "8.1.3.1"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use sqlite3 as the database for Active Record
# gem "sqlite3", ">= 1.4"
# # Use the Puma web server [https://github.com/puma/puma]
# gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
# gem "importmap-rails"

gem "bootsnap", require: false
gem "dartsass-rails"
gem "diffy"
gem "erb_lint"
gem "gds-api-adapters"
gem "gds-sso"
gem "govuk_app_config", "~> 9.25.2"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "nokodiff", github: "alphagov/nokodiff", ref: "bb1aa48d961bc88eac94122725507bdbe1dd10d1"
gem "notifications-ruby-client"
gem "pg"
gem "plek"
gem "sentry-sidekiq"
gem "terser"
gem "uglifier"

group :development do
  gem "listen"
end

group :test do
  gem "climate_control"
  gem "simplecov", "~>1.1"
end

group :development, :test do
  gem "byebug"
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "rspec-html-matchers"
  gem "rspec-rails"
  gem "rubocop-govuk"
end
