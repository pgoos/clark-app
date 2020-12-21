# frozen_string_literal: true

# TODO: Implement better solution for working items steps
When(/^admin clicks on the test (mandate|inquiry|opportunity|product|appointment|contract|address) id in a table$/) do |entity_id|
  case entity_id
  when "appointment"
    AppointmentsPage.new.click_on_appointments_id(@customer)
  when "mandate"
    MandatesPage.new.click_on_mandate_id(@customer)
  when "inquiry"
    InquiriesPage.new.click_on_inquiry_id(@customer)
  when "opportunity"
    OpportunitiesPage.new.click_on_opportunity_id(@customer)
  when "product"
    ProductsPage.new.click_on_product_id(@new_product_number)
  when "contract"
    WorkItemsPage.new.click_on_contract_id(@new_product_number)
  when "address"
    WorkItemsPage.new.click_address_change_id_by(@customer)
  else
    raise ArgumentError.new
  end
end

# This step requires @customer != nil
# Use @requires_mandate tag on your scenario to initialize @customer
When(/^admin accepts users mandate$/) do
  step "admin is logged in ops ui"
  step 'admin clicks on "Kunden" link'
  step "admin clicks on the #{@customer.first_name} mandate in a table"
  step 'admin clicks on "Akzeptieren" link'
end

When(/^admin clicks on the ([^"]*) mandate in a table$/) do |source|
  MandatesPage.new.click_on_mandate_id_by_source(source)
end

Then(/^admin sees (?:mandate|product|opportunity|) status as "([^"]*)"$/) do |status|
  OpportunityDetailsPage.new.assert_status(status)
end

Then(/^admin sees "([^"]*)" input field$/) do |field|
  expect(page).to have_selector("##{field}", wait: 2)
end

Then(/^admin sees table with populated data present on page$/) do
  OpsuiPage.new.assert_data_table_present
end

Then(/^admin sees "([^"]*)" link on page$/) do |text|
  expect(page).to have_selector("a", text: text, match: :prefer_exact, wait: 2)
end

Then(/^admin does not see "([^"]*)" link on page$/) do |text|
  expect(page).not_to have_selector("a", text: text, match: :prefer_exact, wait: 2)
end
