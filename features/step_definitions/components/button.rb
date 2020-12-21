# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) clicks on "([^"]*)" button$/) do |text|
  button_page_context.click_on_button(text)
end

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) hovers on "([^"]*)" button$/) do |text|
  button_page_context.hover_over_button(text)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees that "([^"]*)" button is visible/) do |text|
  button_page_context.assert_button_is_visible(text)
end

Then(/^(?:user|admin) sees that "([^"]*)" button is disabled$/) do |text|
  button_page_context.assert_button_is_disabled(text)
end

And(/^(?:user) sees dropdown menu with add contracts options$/) do
  button_page_context.assert_contracts_adding_options
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Button]
def button_page_context
  PageContextManager.assert_context(Components::Button)
  PageContextManager.context
end
