# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user fills the profiling form with their data$/) do
  profiling_page_context.fill_profiling_form(@customer)
end

# TODO: refactor in order to use form component
When(/^user updates the profile information with following values$/) do |table|
  table.hashes[0].each do |details, value|
    profiling_page_context.set_field_value(details, value)
  end
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees that the GDPR conditions acceptance string ends with current date$/) do
  profiling_page_context.assert_gdpr_acceptance_date(Time.now.strftime("%d.%m.%Y"))
end

Then(/^user sees that the profile form is filled with the following values$/) do |table|
  table.hashes[0].each do |details, value|
    profiling_page_context.assert_field_value(details, value)
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::Profiling]
def profiling_page_context
  PageContextManager.assert_context(AppPages::AbstractProfiling)
  PageContextManager.context
end
