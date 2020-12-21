# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) opens ([^"]*) menu(?: \[mobile view only\])?$/) do |menu|
  menu_page_context.open_menu(menu)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Menu]
def menu_page_context
  PageContextManager.assert_context(Components::Menu)
  PageContextManager.context
end
