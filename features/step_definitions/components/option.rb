# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) selects(?:\s"([^"]*)")? ([^"]*) (?:(sub))?option$/) do |option, marker, is_suboption|
  option_page_context.select_option(marker, option, is_suboption.presence)
end

When(/^(?:user|admin) selects ([^"]*) (?:(sub))?options$/) do |marker, is_suboption, table|
  option_page_context.select_options(marker, table, is_suboption.presence)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Option]
def option_page_context
  PageContextManager.assert_context(Components::Option)
  PageContextManager.context
end
