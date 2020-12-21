# frozen_string_literal: true

require_relative "page_context_manager.rb"
require_relative "repository/path_table.rb"

# Basic hooks ----------------------------------------------------------------------------------------------------------

Before do |scenario|
  Capybara.current_session.driver.quit
  Capybara.session_name = ":session_#{Time.now.to_i}"
  Capybara.app_host = TestContextManager.instance.target_url
  PageContextManager.init(Repository::PathTable)
  Helpers::ReportingHelper.start_capturing_traffic(scenario)
end

After do |scenario|
  Helpers::ReportingHelper.take_screenshot(scenario) if scenario.failed?
  if %I[chrome headless_chrome remote_chrome].include?(Capybara.javascript_driver)
    Helpers::ReportingHelper.capture_browser_logs
  end
  Helpers::ReportingHelper.save_captured_traffic_to_file
ensure
  Capybara.current_session.driver.browser.manage.delete_all_cookies
end

# Tags hooks -----------------------------------------------------------------------------------------------------------

Before("not @enable_tracking_scripts") do
  unless TestContextManager.instance.enable_tracking_scripts?
    Capybara.current_session.visit "/de/tracking/opt-out"
  end
end

Before("@requires_mandate") do
  # TODO: register mandate with random amount(1-10) of random inquiries
  @customer = TestContextManager.instance.mandate_helper.generate_mandate
  TestContextManager.instance.mandate_helper.register_mandate(@customer)
end

Before("not @enable_cookie_banner") do
  Capybara.current_session.visit "/"
  raise "The page is not opened or unable to visit the url provided" if Capybara.current_session.current_url.nil?
  Capybara.current_session.driver.browser.manage.add_cookie(name: "hide-cookies-banner", value: "true")
end
