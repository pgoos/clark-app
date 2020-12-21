# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees (?:text|message) "([^"]*)"$/) do |text|
  text_page_context.assert_text(text)
end

Then(/^(?:user|admin) sees text$/) do |markdown|
  text_page_context.assert_text(markdown.gsub!("\n", " "))
end

Then(/^(?:user|admin) doesn't see (?:text|message) "([^"]*)"$/) do |text|
  text_page_context.assert_no_text(text)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Text]
def text_page_context
  PageContextManager.assert_context(Components::Text)
  PageContextManager.context
end
