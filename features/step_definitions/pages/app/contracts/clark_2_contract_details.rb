# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees that ([1-4])(?:st|nd|rd|th) stage of progress bar is in ([^"]*) state and has "([^"]*)" title$/) do |num, state, title|
  clark_2_contract_details_page_context.assert_progress_bar_stage(num.to_i, state, title)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::Clark2ContractDetails]
def clark_2_contract_details_page_context
  PageContextManager.assert_context(AppPages::Clark2ContractDetails)
  PageContextManager.context
end
