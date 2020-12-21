# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user selects "([^"]*)" radio button for ([^"]*)$/) do |option, marker|
  radio_button_page_context.select_radio_button(option, marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::RadioButton]
def radio_button_page_context
  PageContextManager.assert_context(Components::RadioButton)
  PageContextManager.context
end
