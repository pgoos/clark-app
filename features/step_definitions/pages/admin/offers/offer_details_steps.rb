# frozen_string_literal: true

When(/^offer is in "([^"]*)" status$/) do |status|
  offer_details.assert_status(status)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AdminPages::OpportunityOffer]
def offer_details
  PageContextManager.assert_context(AdminPages::OpportunityOffer)
  PageContextManager.context
end
