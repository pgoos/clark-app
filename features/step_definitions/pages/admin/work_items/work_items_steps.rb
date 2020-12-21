# frozen_string_literal: true

When(/^admin assigns the first incoming message to "([^"]*)"$/) do |name|
  Helpers::OpsUiHelper.select_combobox_option("assign_admin", name)
end

When(/^admin clicks on "([^"]*)" button for test contract id in customer uploaded contract documents table$/) do |button_name|
  WorkItemsPage.new.click_button_in_table(@new_product_number, button_name)
end

Then(/^admin sees first incoming message assigned to "([^"]*)"$/) do |name|
  expect(Helpers::OpsUiHelper.get_combobox_option("assign_admin")).to eq(name)
end

Then(/^admin sees populated incoming messages table on page$/) do
  Helpers::NavigationHelper.wait_for_resources_downloaded
  expect(Helpers::OpsUiHelper::TableHelper.new(parent_id: "incoming_messages").rows_number).not_to eq(0)
end

And(/^admin does not see current user in the changed adresses table$/) do
  WorkItemsPage.new.assert_customer_is_not_in_table(@customer)
end

And(/^admin sees current user in the changed addresses table$/) do
  WorkItemsPage.new.assert_customer_is_in_table(@customer)
end

Then(/^admin sees populated customer uploaded contract documents table on page$/) do
  Helpers::NavigationHelper.wait_for_resources_downloaded
  WorkItemsPage.new.assert_table_is_not_empty
end

Then(/^admin sees test contract id in customer uploaded contract documents table$/) do
  Helpers::NavigationHelper.wait_for_resources_downloaded
  WorkItemsPage.new.assert_id_present_in_table(@new_product_number)
end

Then(/^admin does not see test contract id in customer uploaded contract documents table$/) do
  Helpers::NavigationHelper.wait_for_resources_downloaded
  WorkItemsPage.new.assert_id_is_not_present_in_table(@new_product_number)
end
