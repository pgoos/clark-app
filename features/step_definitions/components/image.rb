# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^(?:user|admin) sees ([^"]*) image$/) do |marker|
  image_page_context.assert_image(marker)
end

Then(/user does not see ([^"]*) image$/) do |marker|
  image_page_context.assert_not_to_have_image(marker)
end
# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Image]
def image_page_context
  PageContextManager.assert_context(Components::Image)
  PageContextManager.context
end
