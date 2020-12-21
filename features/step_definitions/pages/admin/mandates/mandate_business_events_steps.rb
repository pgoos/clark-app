# frozen_string_literal: true

Then(/^admin sees the update address metadata table with "([^"]*)" in column (\d+) of row (\d+)$/) do |cell_text, column_number, row_number|
  @mandate_business_events_page = MandatesBusinessEventsPage.new
  @mandate_business_events_page.assert_update_address_metadata(cell_text, column_number, row_number)
end
