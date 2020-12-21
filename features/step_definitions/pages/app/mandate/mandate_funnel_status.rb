# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees the following information about Clark$/) do |table|
  patiently do
    mandate_funnel_status_page_context.assert_registration_steps(table)
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::MandateFunnelStatus]
def mandate_funnel_status_page_context
  PageContextManager.assert_context(AppPages::MandateFunnelStatus)
  PageContextManager.context
end
