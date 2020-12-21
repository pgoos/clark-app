# frozen_string_literal: true

module Components
  # This component is responsible for the page text assertions
  module Text
    # Method asserts that page contains target text
    # @param text [String] target text
    def assert_text(text)
      expect(page).to have_text(text, normalize_ws: true)
    end

    # Method asserts that page doesn't contain target text
    # @param text [String] target text
    def assert_no_text(text)
      expect(page).not_to have_text(text, normalize_ws: true, wait: 5)
    end
  end
end
