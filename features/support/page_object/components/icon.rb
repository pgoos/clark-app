# frozen_string_literal: true

module Components
  # This component is responsible for interactions with icons
  module Icon
    # Method clicks on the icon
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def click_profile_icon(icon) { }
    # @param marker [String] custom method marker
    # @param icon [String, nil] concrete icon sign
    def click_icon(marker, icon=nil)
      send("click_#{marker.tr(' ', '_')}_icon", icon)
      sleep 0.25
    end

    # Method hovers on the icon
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def hover_on_profile_icon() { }
    # @param marker [String] custom method marker
    def hover_on_icon(marker)
      send("hover_on_#{marker.tr(' ', '_')}_icon")
      sleep 0.25
    end

    # Method asserts that page contains provided number of icons
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_product_icons(icons_number) { }
    # @param marker [String] custom method marker
    # @param icons_number [Integer] expected quantity of icons
    def assert_icons(marker, icons_number)
      send("assert_#{marker.tr(' ', '_')}_icons", icons_number)
    end
  end
end
