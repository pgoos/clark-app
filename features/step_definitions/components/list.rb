# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees ([^"]*) list$/) do |marker|
  list_page_context.assert_list(marker, nil)
end

Then(/^(?:user|admin) sees ([^"]*) list with$/) do |marker, table|
  list_page_context.assert_list(marker, table)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::List]
def list_page_context
  PageContextManager.assert_context(Components::List)
  PageContextManager.context
end
