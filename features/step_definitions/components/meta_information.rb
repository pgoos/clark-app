# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees that the page title is "([^"]*)"$/) do |page_title|
  meta_information_page_context.assert_page_title(page_title)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::MetaInformation]
def meta_information_page_context
  PageContextManager.assert_context(Components::MetaInformation)
  PageContextManager.context
end
