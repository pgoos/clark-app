# frozen_string_literal: true

require_relative "../../../../../components/file_upload.rb"
require_relative "../../../../page.rb"

module AppPages
  # /de/app/retirement/wizards/new/upload-documents
  class UploadDocuments
    include Page
    include Components::FileUpload
  end
end
