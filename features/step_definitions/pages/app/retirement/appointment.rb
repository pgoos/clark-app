# When -----------------------------------------------------------------------------------------------------------------

When(/^clark version is "([^"]*)" and cockpit preview experiment is set to "([^"]*)" variation$/) do |clark_version, variation|
  set_retirement_cta_variation(clark_version, variation)
end

private

def set_retirement_cta_variation(clark_version, variation)
  variation = { "business-strategy": clark_version, "retirement:make-appointment": variation }.to_json
  js = "window.localStorage.setItem('clark-experiments', '#{variation}')"
  Capybara.current_session.execute_script(js)
  Capybara.current_session.driver.browser.navigate.refresh
end
