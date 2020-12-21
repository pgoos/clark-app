# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees ([^"]*) page header is visible(?: \[desktop view only\])?$/) do |marker|
  header_page_context.assert_page_header_is_visible(marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Header]
def header_page_context
  PageContextManager.assert_context(Components::Header)
  PageContextManager.context
end
