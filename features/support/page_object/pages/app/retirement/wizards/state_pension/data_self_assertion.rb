# frozen_string_literal: true

require_relative "../../../../../components/file_upload.rb"
require_relative "../../../../../components/modal.rb"
require_relative "../../../../page.rb"

module AppPages
  # /de/app/retirement/wizards/state-pension/input-details
  class DataSelfAssertion
    include Page
    include Components::FileUpload
    include Components::Modal

    INFO_MODAL_CSS = "div.ember-modal-dialog"
    private_constant :INFO_MODAL_CSS

    private

    # extend Components::Input -----------------------------------------------------------------------------------------
    def enter_value_into_guaranteed_pension_input_field(pension_amount)
      find("input[data-test-state-input]").set(pension_amount)
      sleep 0.25
    end

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def assert_info_modal
      # find parent modal element and check some child elements
      information_modal = find(INFO_MODAL_CSS)
      information_modal.find("#Ihre-Renteninformati")
      information_modal.find("#Deutsche_Rentenversicherung_logo")
      information_modal.find("#Herr-Max-Mustermann")
    end

    def close_info_modal
      # parent information modal contains only one button
      find(INFO_MODAL_CSS).find("button").click
      assert_no_selector(:css, INFO_MODAL_CSS, wait: 5)
    end
  end
end
