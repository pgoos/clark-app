# frozen_string_literal: true

module Components
  # This component provides methods for performing file upload operations
  module FileUpload
    DEFAULT_UPLOADING_FILE = "retirement_cockpit.pdf"

    # Method uploads file
    # Custom method can be implemented. Example: def upload_retirement_document() { }
    # @param marker [String] custom method marker
    # @param doc_name [String] document name. Doc should be present in features/support/upload_files
    def upload_document(marker, doc_name)
      # dispatch
      custom_method = "upload_#{marker.tr(' ', '_')}_document"
      if respond_to?(custom_method, true)
        send(custom_method, doc_name)
        sleep 0.25
        return
      end

      # default generic implementation
      upload_document_in_app(doc_name)
    end

    # Method attaches file for uploading in OPS UI
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def attach_xls_file_for_uploading(file_path) { }
    # @param marker [String] custom method marker
    # @param file_path [String, nil] path of file for uploading
    def attach_file_for_uploading(marker, file_path=nil)
      send("attach_#{marker.tr(' ', '_')}_file_for_uploading", file_path)
      sleep 0.25
    end

    private

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # method used for performing upload doc operation on several application pages
    def upload_document_in_app(doc_name=nil)
      doc_name = DEFAULT_UPLOADING_FILE if doc_name.nil?

      selector = ".file-upload > input"
      input_xpath = "//*[starts-with(@id, 'file-input')]"

      # Capybara doesn't interact with non-visible elements,
      # removing hidden attribute and make visible for file selection
      Capybara.current_session.execute_script("document.querySelector('#{selector}').removeAttribute('hidden')")
      expect(page).to have_xpath(input_xpath, visible: true)
      page.attach_file(
        find(:xpath, input_xpath)["id"],
        Helpers::OSHelper.upload_file_path(doc_name)
      )
    end
  end
end
