# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) enters (?:"([^"]*)"|random string) into ([^"]*) input field$/) do |value, marker|
  input_page_context.enter_value_into_input_field(value, marker)
end

When(/^(?:user|admin) enters (?:their|customer) ([^"]*) data?$/) do |marker|
  input_page_context.enter_customer_data(@customer, marker)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees ([^"]*) input field$/) do |marker|
  input_page_context.assert_input_field(marker)
end

When(/^user sees "([^"]*)" text in ([^"]*) input field$/) do |value, marker|
  input_page_context.assert_text_in_input_field(value, marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Input]
def input_page_context
  PageContextManager.assert_context(Components::Input)
  PageContextManager.context
end
