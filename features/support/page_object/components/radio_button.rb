# frozen_string_literal: true

module Components
  # This component is responsible for interactions with radio buttons
  module RadioButton
    # Method selects radio button for the selected group
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def select_gender_radio_button(option) { }
    # @param option [String] option value
    # @param marker [String] custom method marker
    def select_radio_button(option, marker)
      send("select_#{marker.tr(' ', '_')}_radio_button", option)
      sleep 0.25
    end
  end
end
