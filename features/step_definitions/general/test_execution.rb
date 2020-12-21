# frozen_string_literal: true

# Contains steps definitions, required for the test execution management

# Steps below this will be skipped for the if mobile browser is used as a Capybara Driver
# The test will be marked as 'skipped'
Given(/^skip below steps in mobile browser$/) do
  skip_this_scenario if TestContextManager.instance.mobile_browser?
end
