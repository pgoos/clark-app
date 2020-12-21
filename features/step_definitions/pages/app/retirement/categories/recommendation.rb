# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees the statistics map$/) do
  recommendation_page_context.assert_statistics_map
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::RetirementSingleRecommendation]
def recommendation_page_context
  PageContextManager.assert_context(AppPages::RetirementSingleRecommendation)
  PageContextManager.context
end
