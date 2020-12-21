# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user scrolls to ([^"]*)$/) do |marker|
  scroll_page_context.scroll_to(marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Scroll]
def scroll_page_context
  PageContextManager.assert_context(Components::Scroll)
  PageContextManager.context
end
