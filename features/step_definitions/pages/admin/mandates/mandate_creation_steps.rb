# frozen_string_literal: true

And(/^admin enters the mandate email address$/) do
  # Modify this with better solution of using same css selector in opsui with other email fields,
  # probably after opsui is implemented with ember
  @mandate_creation_page ||= MandateCreationPage.new(@customer)
  @mandate_creation_page.fill_mandate_email_id
end

And(/^admin enters the mandate user email address$/) do
  # Modify this with better solution of using same css selector in opsui with other email fields,
  # probably after opsui is implemented with ember
  @mandate_creation_page ||= MandateCreationPage.new(@customer)
  @mandate_creation_page.fill_mandate_user_email_id
end

And(/^admin enters the password$/) do
  @mandate_creation_page.fill_password
end

And(/^admin enters the password confirmation$/) do
  @mandate_creation_page.fill_password_confirmation
end

And(/^admin selects the owner as "([^"]*)"$/) do |owner_name|
  @mandate_creation_page.select_owner(owner_name)
end

And(/^admin enters the reference number as "([^"]*)"$/) do |reference_id|
  @mandate_creation_page.fill_reference_id(reference_id)
end

And(/^admin uploads the mandate document$/) do
  @mandate_creation_page.upload_mandate_document
end

