# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) fills out "([^"]*)" form$/) do |marker, table|
  form_page_context.fill_out_form(marker, table.hashes)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Form]
def form_page_context
  PageContextManager.assert_context(Components::Form)
  PageContextManager.context
end
