# frozen_string_literal: true

module Components
  # This component is responsible for interactions with page header
  module Header
    # Method asserts that page header is visible
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_cms_page_header_is_visible() { }
    # @param marker [String] custom method marker
    def assert_page_header_is_visible(marker)
      send("assert_#{marker.tr(' ', '_')}_page_header_is_visible")
    end
  end
end
