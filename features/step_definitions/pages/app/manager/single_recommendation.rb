# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees the quality standard section with (\d+) icons$/) do |icons_quantity|
  single_recommendation_page_context.assert_quality_standard(icons_quantity)
end

Then(/^user sees Why Clark footer section with following content$/) do |table|
  single_recommendation_page_context.assert_why_clark_footer_section(table)
end

# Context --------------------------------------------------------------------------------------------------------------

private

def single_recommendation_page_context
  PageContextManager.assert_context(AppPages::SingleRecommendation)
  PageContextManager.context
end
