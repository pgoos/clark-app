# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/user sees(?:\s"([^"]*)")? ([^"]*) label$/) do |label, marker|
  label_page_context.assert_label(marker, label.presence)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Label]
def label_page_context
  PageContextManager.assert_context(Components::Label)
  PageContextManager.context
end
