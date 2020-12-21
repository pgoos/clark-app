# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------
Then(/^user sees "([^"]*)" recommendations in recommendation list$/) do |categories|
  patiently do
    recommendations_page_context.assert_recommendation_cards(categories)
  end
end

And(/^user sees "([^"]*)" in recommendation rings for "([^"]*)" section$/) do |text, marker|
  recommendations_page_context.assert_numbers_in_recommendations_rings(text, marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::Recommendations]
def recommendations_page_context
  PageContextManager.assert_context(AppPages::Recommendations)
  PageContextManager.context
end
