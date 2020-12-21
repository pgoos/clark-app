# frozen_string_literal: true

module Components
  # This component provides methods assertion of page meta information
  module MetaInformation
    # Methods asserts that current page title is equal to the expected
    # @param page_title [String] expected page title
    def assert_page_title(page_title)
      expect(page).to have_title(page_title)
    end
  end
end
