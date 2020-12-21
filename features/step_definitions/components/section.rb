# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees(?:\s"([^"]*)")? ([^"]*) section$/) do |section, marker|
  section_page_context.assert_section(marker, section.presence)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Section]
def section_page_context
  PageContextManager.assert_context(Components::Section)
  PageContextManager.context
end
