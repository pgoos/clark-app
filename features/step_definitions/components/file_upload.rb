# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user uploads ([^"]*) document(?:\s?"([^"]*)")?$/) do |marker, doc_name|
  file_upload_page_context.upload_document(marker, doc_name.presence)
end

When(/^admin attaches ([^"]*) file for uploading$/) do |marker|
  file_upload_page_context.attach_file_for_uploading(marker, @ff_payments_file.path)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::FileUpload]
def file_upload_page_context
  PageContextManager.assert_context(Components::FileUpload)
  PageContextManager.context
end
