# frozen_string_literal: true

module Components
  # This component is responsible for interactions with checkboxes
  module Checkbox
    # Method selects checkbox
    # WARNING: If checkbox is already selected, can unselect it! (depend on custom method realization)
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def select_accept_rules_checkbox() { }
    # @param marker [String] custom method marker
    def select_checkbox(marker)
      send("select_#{marker.tr(' ', '_')}_checkbox")
      sleep 0.25
    end
  end
end
