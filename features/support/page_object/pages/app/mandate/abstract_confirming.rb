# frozen_string_literal: true

require_relative "../../page.rb"
require_relative "../../../components/checkbox.rb"
require_relative "../../../components/label.rb"
require_relative "../../../components/modal.rb"

module AppPages
  # /de/app/mandate/confirming
  # /de/app/customer/upgrade/signature
  class AbstractConfirming
    include Page
    include Components::Checkbox
    include Components::Label
    include Components::Modal

    # Page specific methods --------------------------------------------------------------------------------------------
    # TODO: draw something more charming
    # Method draws signature
    def draw_signature
      within_frame(insign_element) do
        element = find("canvas.wizard-confirmation__signature__canvas-wrapper__canvas")
        page.driver.browser.action.move_to(element.native)
            .click_and_hold
            .move_by(25, 0)
            .move_by(0, 25)
            .move_by(-50, 0)
            .move_by(0, -50)
            .move_by(25, 25)
            .release
            .perform
      end
    end

    private

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def assert_signature_modal_is_closed
      assert_modal_is_closed("Diese Unterschrift kann von deiner normalen Unterschrift abweichen")
    end

    def click_insign_button
      find(".cucumber-signature-modal-trigger").click
    end

    # @abstract
    def insign_element
      NotImplementedError.new
    end
  end
end
