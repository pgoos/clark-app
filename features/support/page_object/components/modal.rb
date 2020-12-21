# frozen_string_literal: true

require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component provides methods for the interaction with modal windows
  module Modal
    extend Helpers::Wrappers

    sleep_after 1, :close_modal
    sleep_after 0.5, :assert_modal, :assert_modal_is_closed

    # Method asserts that modal is displayed
    # Custom method can be implemented. Example: def assert_signature_modal() { }
    # @param marker [String, nil] custom method marker OR text in modal window
    def assert_modal(marker)
      # dispatch
      custom_method = "assert_#{marker.tr(' ', '_')}_modal"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      # TODO: this checks are inadequate. Add more full-fledged assertions here
      expect(page).to have_selector(".ember-modal-dialog")
      expect(page).to have_text(marker)
    end

    # Method asserts that modal is not displayed
    # Custom method can be implemented. Example: def assert_signature_modal_is_closed() { }
    # @param marker [String, nil] custom method marker OR text in modal window
    def assert_modal_is_closed(marker)
      # dispatch
      custom_method = "assert_#{marker.tr(' ', '_')}_modal_is_closed"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      # TODO: this check is inadequate. Add more full-fledged assertions here
      page.assert_no_text(marker, wait: 5)
    end

    # Method closes modal
    # Custom method can be implemented. Example: def close_help_modal() { }
    # @param marker [String, nil] custom method marker OR text in modal window
    def close_modal(marker)
      # dispatch
      custom_method = "close_#{marker.tr(' ', '_')}_modal"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      return unless page.has_css?("#modal-overlays")
      find("#modal-overlays .cucumber-close-modal").click
      assert_no_selector(:css, ".cucumber-close-modal", wait: 5)
      page.assert_no_text(marker, wait: 5)
    end
  end
end
