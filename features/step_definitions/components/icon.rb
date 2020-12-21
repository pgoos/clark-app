# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user clicks(?:\s?"([^"]*)")? ([^"]*) icon$/) do |icon, marker|
  icon_page_context.click_icon(marker, icon.presence)
end

When(/^user hovers on ([^"]*) icon$/) do |marker|
  icon_page_context.hover_on_icon(marker)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees (?:(\d+)) ([^"]*) icons?$/) do |icons_number, marker|
  icon_page_context.assert_icons(marker, icons_number.presence)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Icon]
def icon_page_context
  PageContextManager.assert_context(Components::Icon)
  PageContextManager.context
end
