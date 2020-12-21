# frozen_string_literal: true

And(/^admin remembers the number of existing documents$/) do
  @inquiry_details_page ||= InquiryDetailsPage.new
  @inquiry_details_page.set_docs_number
end


And(/^admin sees that the number of documents increased by (\d+)$/) do |by_count|
  @inquiry_details_page.assert_docs_number_increased(by_count)
end

And(/^admin attaches file for uploading$/) do
  @inquiry_details_page.attach_inquiry_document_file_for_uploading
end

And(/^admin cancells the inquiry with a "([^"]*)" reason$/) do |reason|
  InquiryDetailsPage.new.inquiry_cancellation(reason)
end

Then(/^admin sees that the number of existing documents is (\d+)$/) do |document_number|
  @inquiry_details_page.assert_docs_number(document_number)
end
