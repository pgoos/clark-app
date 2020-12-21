# frozen_string_literal: true

module Components
  # This component is responsible for performing operations with slider
  module Slider
    # Method moves slider to the target value
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def move_age_slider(value) { }
    # @param marker [String] custom method marker
    # @param value [String] target value
    def move_slider(marker, value)
      send("move_#{marker.tr(' ', '_')}_slider", value)
    end

    # Method asserts that slider is present
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_amount_slider(value) { }
    # @param marker [String] custom method marker
    def assert_slider(marker)
      send("assert_#{marker.tr(' ', '_')}_slider")
    end
  end
end
