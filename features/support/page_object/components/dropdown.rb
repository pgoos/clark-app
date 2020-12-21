# frozen_string_literal: true

module Components
  # This component is responsible for interactions with dropdowns
  module Dropdown
    # Method selects target option in a dropdown
    # By default searches the dropdown by label
    # Custom method can be implemented. Example: def select_type_dropdown_option(option) { }
    # @param option [String] target option
    # @param marker [String] dropdown label or custom method marker
    def select_dropdown_option(option, marker)
      # dispatch
      unless marker.nil?
        custom_method = "select_#{marker.tr(' ', '_')}_dropdown_option"
        return send(custom_method, option) if respond_to?(custom_method, true)
      end

      # default generic implementation
      find("label", text: marker).find(:xpath, "..").click unless marker.nil? # open dropdown
      find("div.ember-power-select-option", text: option, match: :prefer_exact).click # select an option
      sleep 0.25
    end
  end
end
