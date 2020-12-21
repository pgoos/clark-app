# frozen_string_literal: true

require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component is responsible for interactions with buttons
  module Button
    extend Helpers::Wrappers

    sleep_after 0.25, :click_on_button, :assert_button_is_visible, :hover_over_button

    # Method clicks on button
    # By default searches the button by provided text
    # Custom method can be implemented. Example: def click_send_button() { }
    # @param text [String] button text or custom method marker
    def click_on_button(text)
      # dispatch
      custom_method = "click_#{text.tr(' ', '_')}_button"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      find_button(text, match: :first).click
    end

    # Method asserts that button is visible
    # By default searches the button by provided text
    # Custom method can be implemented. Example: def assert_print_button_is_visible() { }
    # @param text [String] button text or custom method marker
    def assert_button_is_visible(text)
      # dispatch
      custom_method = "assert_#{text.tr(' ', '_')}_button_is_visible"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      expect(page).to have_button(text, visible: true)
    end

    # Method hovers over the button.
    # Searches for the button link by provided text
    # Can handle 'button' links only
    # @param text [String] button text
    def hover_over_button(text)
      # dispatch
      custom_method = "hover_over_#{text.tr(' ', '_')}_button"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      find("button", text: text).hover
    end

    # Method asserts that button is disabled
    # By default searches the button by provided text
    # Custom method can be implemented. Example: def assert_next_button_is_disabled() { }
    # @param text [String] button text or custom method marker
    def assert_button_is_disabled(text)
      # dispatch
      custom_method = "assert_#{text.tr(' ', '_')}_button_is_disabled"
      return send(custom_method) if respond_to?(custom_method, true)

      # default generic implementation
      expect(page).to have_button(text, disabled: true)
    end
  end
end
