# frozen_string_literal: true

module Components
  # This component provides methods for the interactions with page sections (documents, rating, etc)
  module Section
    # Method asserts that target section is visible
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def scroll_to_documents_section() { }
    # @param marker [String] custom method marker
    # @param section [String, nil] concrete section sign
    def assert_section(marker, section=nil)
      send("assert_#{marker.tr(' ', '_')}_section", section)
    end
  end
end
