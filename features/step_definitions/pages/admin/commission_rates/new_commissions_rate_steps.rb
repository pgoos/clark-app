# frozen_string_literal: true

When(/^admin selects "([^"]*)" as the commission rate sales channel$/) do |channel|
  @new_commission_rate ||= NewCommissionRate.new
  @new_commission_rate.select_sales_channel(channel)
end

Then(/^admin sees ([^"]*) as default "([^"]*)" commission rate$/) do |value, field|
  @new_commission_rate.assert_default_commission_rate(value, field)
end
