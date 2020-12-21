# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees messenger window opened$/) do
  messenger_page_context.assert_messenger_opened
end

Then(/^user sees their own "([^"]*)" message in the feed$/) do |message|
  messenger_page_context.verify_user_message(message)
end

Then(/^user sees "([^"]*)" admin message in the feed$/) do |message|
  messenger_page_context.verify_admin_message(message)
end

Then(/^user sees uploaded documents? in the feed$/) do |table|
  messenger_page_context.verify_uploaded_documents(table)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Messenger]
def messenger_page_context
  PageContextManager.assert_context(Components::Messenger)
  PageContextManager.context
end
