# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) closes "([^"]*)" modal$/) do |marker|
  modal_page_context.close_modal(marker)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees "([^"]*)" modal$/) do |marker|
  modal_page_context.assert_modal(marker)
end

Then(/^(?:user|admin) waits until "([^"]*)" modal is closed$/) do |marker|
  modal_page_context.assert_modal_is_closed(marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Modal]
def modal_page_context
  PageContextManager.assert_context(Components::Modal)
  PageContextManager.context
end

