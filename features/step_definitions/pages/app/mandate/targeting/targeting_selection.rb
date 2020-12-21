# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user can see inquiry with "([^"]*)" category and "([^"]*)" company$/) do |category, company|
  patiently do
    targeting_selection_page_context.assert_selected_inquiry(category, company)
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::TargetingSelection]
def targeting_selection_page_context
  PageContextManager.assert_context(AppPages::AbstractTargeting)
  PageContextManager.context
end
