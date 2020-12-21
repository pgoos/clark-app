# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) moves ([^"]*) slider to "([^"]*)"$/) do |marker, value|
  slider_page_context.move_slider(marker, value)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees ([^"]*) slider$/) do |marker|
  slider_page_context.assert_slider(marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Slider]
def slider_page_context
  PageContextManager.assert_context(Components::Slider)
  PageContextManager.context
end
