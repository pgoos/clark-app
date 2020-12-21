# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user is on the "([^"]*)" category company targeting path$/) do |category|
  patiently do
    company_selection_page_context.assert_company_targeting_path(category)
  end
end

Then(/^user sees the company search results$/) do
  company_selection_page_context.assert_search_results
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::CompanySelection]
def company_selection_page_context
  PageContextManager.assert_context(AppPages::CompanySelection)
  PageContextManager.context
end
