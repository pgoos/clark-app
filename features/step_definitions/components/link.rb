# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^(?:user|admin) clicks on "([^"]*)" link$/) do |text|
  link_page_context.click_on_link(text)
end

When(/^(?:user|admin) scrolls to and clicks on "([^"]*)" link$/) do |text|
  link_page_context.click_on_link(text, true)
end

When(/^(?:user|admin) hovers on "([^"]*)" link$/) do |text|
  link_page_context.hover_over_link(text)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees that "([^"]*)" (?:(target)\s)?link is visible$/) do |text, is_target_link|
  link_page_context.assert_link_is_visible(text, is_target_link.presence, nil)
end

Then(/^(?:user|admin) sees that "([^"]*)" "([^"]*)" link is visible$/) do |text, link|
  link_page_context.assert_link_is_visible(text, nil, link)
end

Then(/^(?:user|admin) sees that links are visible/) do |table|
  table.raw.each do |text, link|
    link_page_context.assert_link_is_visible(text, nil, link)
  end
end

Then(/^(?:user|admin) sees that "([^"]*)" link is not visible$/) do |text|
  link_page_context.assert_link_is_not_visible(text, nil)
end

Then(/^(?:user|admin) sees that links are not visible/) do |table|
  table.raw.each do |text, link|
    link_page_context.assert_link_is_not_visible(text, link)
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Link]
def link_page_context
  PageContextManager.assert_context(Components::Link)
  PageContextManager.context
end
