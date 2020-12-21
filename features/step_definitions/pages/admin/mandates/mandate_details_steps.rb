# frozen_string_literal: true

And(/^admin remembers the number of existing products$/) do
  @mandate_details ||= AdminPages::MandateDetails.new
  @mandate_details.set_products_number
end

And(/^admin sees that the number of products increased$/) do
  @mandate_details.assert_products_num_increased
end

And(/^admin sees the new product in the first row of products table$/) do
  @mandate_details.assert_new_product_is_in_table(@new_product_number)
end

Then(/^admin sees "([^"]*)" label with the mandate$/) do |mandate_label|
  AdminPages::MandateDetails.new.assert_mandate_label(mandate_label)
end

And(/^admin sees Kommentare input field$/) do
  AdminPages::MandateDetails.new.assert_comment_message_input
end

Then(/^admin sees locked points "([^"]*)"$/) do |points|
  Capybara.using_wait_time 120 do
    skip_refresh = true # skip page refresh for the first attempt
    patiently do
      step "admin refreshes the page" unless skip_refresh
      skip_refresh = false
      AdminPages::MandateDetails.new.assert_locked_points(points)
    end
  end
end

And(/^admin can see that the latest uploaded file is "([^"]*)"$/) do |document_name|
  patiently do
    AdminPages::MandateDetails.new.assert_latest_document_name(document_name)
  end
end

When(/^admin clicks on forward button on latest uploaded document$/) do
  patiently do
    AdminPages::MandateDetails.new.click_forward_latest_document
  end
end

And(/^admin can see the document "([^"]*)" in inquiry details page$/) do |document_name|
  AdminPages::MandateDetails.new.assert_document_in_inquiry(document_name)
end
