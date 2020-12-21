# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) selects "([^"]*)" option in(?:\s?([^"]*)) dropdown$/) do |option, marker|
  dropdown_page_context.select_dropdown_option(option, marker.presence)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Dropdown]
def dropdown_page_context
  PageContextManager.assert_context(Components::Dropdown)
  PageContextManager.context
end
