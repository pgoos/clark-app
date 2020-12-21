# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) selects ([^"]*) checkbox$/) do |marker|
  checkbox_page_context.select_checkbox(marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Checkbox]
def checkbox_page_context
  PageContextManager.assert_context(Components::Checkbox)
  PageContextManager.context
end
