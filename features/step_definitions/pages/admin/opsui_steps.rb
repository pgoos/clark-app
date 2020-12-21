# frozen_string_literal: true

When(/^admin search with the term "([^"]*)"$/) do |search_term|
  OpsuiPage.new.search_mandate(search_term)
end

When(/^admin search by last_name with the term "([^"]*)"$/) do |search_term|
  OpsuiPage.new.search_mandate_by_last_name(search_term)
end

Then(/^admin sees the mandate results$/) do
  OpsuiPage.new.mandate_result
end

And(/^admin clicks the inquiry$/) do
  OpsuiPage.new.clicks_inquiry
end

When(/^admin clicks on the "([^"]*)" link and accept confirmation popup$/) do |text|
  accept_confirm do
    click_link text
  end
end

When(/^admin clicks on the "([^"]*)" button and accept confirmation popup$/) do |text|
  accept_confirm do
    find_button(text, match: :first).click
  end
end

When(/^admin fills "([^"]*)" with customer_last_name$/) do |form_input|
  fill_in form_input, with: @customer.last_name
end

Then(/^admin doesn't see that mismatch$/) do
  page.assert_no_text @new_product_number
end

Then(/^admin does see that mismatch$/) do
  page.assert_text @new_product_number
end

And(/^admin enters message "([^"]*)"$/) do |message|
  patiently do
    OpsuiPage.new.enter_interaction_message(message)
  end
end

And(/^admin can see that the latest message is "([^"]*)"$/) do |message|
  patiently do
    OpsuiPage.new.assert_latest_message(message)
  end
end

And(/^admin sees the inquiry$/) do
  OpsuiPage.new.assert_inquiry_list(nil)
end

When(/^admin clicks on product record edit button$/) do
  Helpers::OpsUiHelper.refresh_if_failed do
    Helpers::NavigationHelper.wait_for_resources_downloaded
    patiently do
      OpsuiPage.new.click_on_section_edit_button(@new_product_number)
    end
  end
end

When(/^admin fills "([^"]*)" with customer ([^"]*)$/) do |form_input, value_type|
  fill_in form_input, with: @customer.to_h[value_type.to_sym]
end

Then(/^admin selects "([^"]*)" as uploaded document type$/) do |doc_type|
  @inquiry_details_page.select_uploaded_doc_type(doc_type)
end

When(/^admin clicks on "([^"]*)" within group "([^"]*)"$/) do |label, group_label|
  form_group = find(:label, text: group_label).find(:xpath, './ancestor::div[contains(@class, "form-group")]')
  form_group.find(:label, text: label).click
end

And(/^admin sees that (\d+) row of "([^"]*)" section contains "([^"]*)"$/) do |row_number, section_heading, text|
  expect(Helpers::OpsUiHelper.get_panel_row_text(section_heading, row_number)).to eq(text)
end

Then(/^admin sees the section with general user information$/) do
  expect(page).to have_text(@customer.birthdate)
  expect(page).to have_text(@customer.email)
  expect(page).to have_text(/#{@customer.address_line1}/i)
  expect(page).to have_text(/#{@customer.place}/i)
  expect(page).to have_text(@customer.zip_code)
end

And(/^admin clicks on "([^"]*)" section eye button$/) do |section_name|
  patiently do
    OpsuiPage.new.click_on_section_eye_button(section_name)
  end
end

Given(/^admin created products$/) do
  steps %Q{
    Given admin is logged in ops ui
    When admin clicks on Kunden" link
    Then admin is on the mandates page
    And admin clicks on the test mandate id in a table
    And admin clicks on Anfrage" section eye button
    And admin clicks on Produkt hinzufügen" link
    When admin selects "Privathaftpflicht" as the product category
    And admin selects "Allianz Versicherung" as the product group
    And admin fills product number with random value
    And admin fills "Vertragsbeginn" with "11122018"
    And admin fills "Prämie" with "10"
    And admin fills "Regelmäßige Provision" with "10"
    And admin selects "monatlich" as the product premium period
    And admin clicks on Anlegen button
  }
end

Given(/^admin uploaded FondsFinanz payment for a created product$/) do
  steps %Q{
    Given admin created products
    When admin clicks on Produkte" link
    And admin clicks on the test product id in a table
    Then admin is on the product_details page
    And admin remembers the number of existing payments
    When admin clicks on Upload Abrechnung" link
    Then admin is on the accounting transactions upload page
    When admin attaches XLSX file exists with payments for that new product
    And admin clicks on Hochladen button
    Then admin sees message "Die Datei wurde hochgeladen und wird verarbeitet."
    When admin clicks on Produkte" link
    And admin clicks on the test product id in a table
    Then admin is on the product_details page
    And admin sees that the number of payments increased
    And admin remembers the number of existing payments
  }
end

Given(/^XLSX file exists with payments for that new product$/) do
  @ff_payments_file = Helpers::XlsxFondFinanzPayments.generate(@new_product_number, @customer)
  @ff_payments_file.rewind
end

Given(/^XLSX file exists with payments for that new product but wrong customer name$/) do
  invalid_customer = @customer.dup
  invalid_customer.last_name = "Wrong"
  @ff_payments_file_wrong_name = Helpers::XlsxFondFinanzPayments.generate(@new_product_number, invalid_customer)
  @ff_payments_file_wrong_name.rewind
end

Given(/^Default XLSX file$/) do
  @ff_payments_file = File.open(Helpers::OSHelper.upload_file_path("accounting_transactions.xlsx"))
  @ff_payments_file.rewind
end

Given(/^Inquiry details file for uploading$/) do
  @ff_payments_file = File.open(Helpers::OSHelper.upload_file_path("retirement_cockpit.pdf"))
  @ff_payments_file.rewind
end

Then(/^admin sees "([^"]*)" page section$/) do |section_heading|
  patiently do
    OpsuiPage.new.assert_page_section(section_heading)
  end
end

When(/^admin attaches XLSX file exists with payments for that new product$/) do
  @ff_payments_file = Helpers::XlsxFondFinanzPayments.generate(@new_product_number, @customer)
  OpsuiPage.new.attach_file_for_uploading(@ff_payments_file.path)
  @ff_payments_file.rewind
end

When(/^admin attaches XLSX file exists with payments for that new product but wrong customer name$/) do
  invalid_customer = @customer.dup
  invalid_customer.last_name = "Wrong"
  ff_payments_file = Helpers::XlsxFondFinanzPayments.generate(@new_product_number, invalid_customer)
  OpsuiPage.new.attach_file_for_uploading(ff_payments_file.path)
  ff_payments_file.rewind
end

When(/^admin attaches the same XLSX file again$/) do
  OpsuiPage.new.attach_file_for_uploading(@ff_payments_file.path)
end

When(/^admin attaches accounting transactions xls for uploading$/) do
  OpsuiPage.new.attach_file_for_uploading
end

Then(/^admin sees that input field for messages is empty$/) do
  patiently do
    OpsuiPage.new.assert_empty_input_field
  end
end

Then(/^admin sees that "([^"]*)" is marked as admin message$/) do |message|
  patiently do
    OpsuiPage.new.assert_admin_message(message)
  end
end
