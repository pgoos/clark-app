# frozen_string_literal: true

module Components
  # This component provides methods for performing scroll operations
  module Scroll
    # Method scrolls to the target element
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def scroll_to_documents_section() { }
    # @param marker [String] custom method marker
    def scroll_to(marker)
      send("scroll_to_#{marker.tr(' ', '_')}")
      sleep 0.25
    end

    private

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # Method scrolls page to the provided css selector
    # @param css_selector [String] target css selector
    def scroll_to_css(css_selector)
      script = "document.querySelector('#{css_selector}').scrollIntoView(true);"
      Capybara.current_session.evaluate_script(script)
    end
  end
end
