# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^admin clicks (\d+)th address change request$/) do |position_in_table|
  @mandate_addresses_page = AdminPages::MandateAddresses.new
  @mandate_addresses_page.click_request_by_position(position_in_table)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^admin sees in the addresses change requests table (\d+) records$/) do |record_count|
  @mandate_addresses_page = AdminPages::MandateAddresses.new
  @mandate_addresses_page.assert_requests_count(record_count)
end
