# frozen_string_literal: true

module Components
  module Image
    # Method asserts that the page contains target Image
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_flower_image() { }
    # @param marker [String] custom method marker
    def assert_image(marker)
      send("assert_#{marker.tr(' ', '_')}_image")
    end

    def assert_not_to_have_image(marker)
      send("assert_not_to_have_#{marker.tr(' ', '_')}_image")
    end

    private

    def assert_statistics_map_image
      expect(page).to have_selector(".cucumber-category-map")
    end
  end
end
