# frozen_string_literal: true

And(/^admin sees that opportunity details page contains appointments table with (\d+) rows$/) do |row_count|
  @opportunity_details_page = OpportunityDetailsPage.new
  @opportunity_details_page.assert_appointment_rows_number(row_count)
end

And(/^admin sees that opportunity details page contains appointments table with "([^"]*)" in column (\d+) of row (\d+)$/) do |cell_text, column_number, row_number|
  @opportunity_details_page.assert_appointment_table_data(cell_text, column_number, row_number)
end
