# frozen_string_literal: true

Then(/^admin sees "([^"]*)" label with the test mandate id in the table$/) do |mandate_label|
  MandatesPage.new.assert_mandate_label_in_table(@customer, mandate_label)
end
