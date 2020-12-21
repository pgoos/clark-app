# frozen_string_literal: true

require_relative "../../page.rb"

# TODO: make this class stateless. @docs_number should be stored in steps definitions

class InquiryDetailsPage
  include Page

  def select_uploaded_doc_type(doc_type)
    Helpers::OpsUiHelper.select_combobox_option("document_document_type_id", doc_type)
  end

  def inquiry_cancellation(reason)
    find("input[value='#{reason}']").click
  end

  def attach_inquiry_document_file_for_uploading
    # attach file for uploading on the 'upload document' page
    attach_file("documents[0][asset][]", Helpers::OSHelper.upload_file_path("retirement_cockpit.pdf"))
  end

  def set_docs_number
    @docs_number = number_of_docs
  end

  def assert_docs_number_increased(by_count=1)
    expect(number_of_docs).to eq(@docs_number + by_count)
  end

  def assert_docs_number(document_number)
    expect(number_of_docs).to eq(document_number)
  end

  private

  def number_of_docs
    Helpers::OpsUiHelper::TableHelper.new(parent_id: "document-details").rows_number
  end
end
