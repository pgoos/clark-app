# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user selects "([^"]*)" (?:date|day) in(?:\s?([^"]*)) calendar$/) do |date, marker|
  calendar_page_context.select_date_in_calendar(date, marker.presence)
end

When(/^user selects "([^"]*)" as ([^"]*) time$/) do |time, marker|
  calendar_page_context.select_time(time, marker)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Calendar]
def calendar_page_context
  PageContextManager.assert_context(Components::Calendar)
  PageContextManager.context
end
