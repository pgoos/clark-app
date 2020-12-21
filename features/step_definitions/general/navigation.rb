# frozen_string_literal: true

# Contains navigation related steps definitions

# Basic navigation -----------------------------------------------------------------------------------------------------

When(/^(?:user|admin) navigates to (.*) page$/) do |path_name|
  Helpers::NavigationHelper.navigate_to_page(path_name)
end

When(/^user navigates back to previous page$/) do
  Capybara.current_session.go_back
  Helpers::NavigationHelper.wait_for_resources_downloaded
end

When(/^(?:user|admin) refreshes the page$/) do
  Helpers::NavigationHelper.refresh_page
  Helpers::NavigationHelper.wait_for_resources_downloaded
end

# Waits for the end of network activity and asserts that current URL is equal to the expected
# WARNING: Page context switch should be performed ONLY inside this step
# Don't change this step (or something within these methods) until you are REALLY sure that you need to do it
Then(/^(?:user|admin) is on the (.*) page$/) do |path_name|
  Helpers::NavigationHelper.wait_for_resources_downloaded
  Capybara.current_session.assert_current_path(Regexp.new(Repository::PathTable[path_name]))
  PageContextManager.switch_context(path_name)
end

# Composite navigation -------------------------------------------------------------------------------------------------

Given(/^user navigates to first page of mandate funnel$/) do
  step "user navigates to home page"
  step "user is on the home page"

  if TestContextManager.instance.desktop_browser?
    step 'user clicks on "Jetzt starten" link'
  else
    step "user opens cms burger menu"
    step 'user clicks on "Einloggen" link'
    step "user is on the login page"
    step 'user clicks on "Registrieren" link'
  end

  step "user is on the mandate funnel status page"
end
