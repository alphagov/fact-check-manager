require "capybara/selenium/driver"

# Chrome 158 rejects the "*" origin that Capybara 3.40.0 passes to the
# Storage.clearDataForOrigin DevTools command in ChromeDriver#reset!, so every
# system spec fails in teardown with:
#
#   Selenium::WebDriver::Error::InvalidArgumentError:
#     invalid argument: * is not a valid URL
#
# Clear the cookies of every origin, and the local storage of the app server's
# origin, instead.
#
# See: https://github.com/teamcapybara/capybara/issues/2865
module CapybaraChromeResetWithoutWildcardOrigin
private

  def execute_cdp(cmd, params = {})
    return super unless cmd == "Storage.clearDataForOrigin" && params[:origin] == "*"

    types = params[:storageTypes].to_s.split(",")
    super("Network.clearBrowserCookies") if types.delete("cookies")

    origin = Capybara.current_session.server&.base_url
    return unless origin && types.any?

    super(cmd, params.merge(origin:, storageTypes: types.join(",")))
  end
end

if Gem::Version.new(Capybara::VERSION) > Gem::Version.new("3.40.0")
  raise <<~MESSAGE
    Capybara has been upgraded to #{Capybara::VERSION}. If it includes the fix for
    https://github.com/teamcapybara/capybara/issues/2865, delete #{__FILE__} and its
    require in spec/rails_helper.rb. Otherwise check the patch still matches
    Capybara::Selenium::Driver::ChromeDriver#reset! and update the version in this check.
  MESSAGE
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeResetWithoutWildcardOrigin)
