# frozen_string_literal: true

require_relative "../../../../../components/calendar.rb"
require_relative "../../../../../components/dropdown.rb"
require_relative "../../../../page.rb"

module AppPages
  # /de/app/retirement/wizards/new/input-details
  class InputDetails
    include Page
    include Components::Calendar
    include Components::Dropdown

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_value_into_retirement_company_input_field(search_term, match_expected=true)
      input_locator = ".ember-power-select-search-input"
      options_locator = ".ember-power-select-option"

      find(input_locator).native.send_keys(search_term)
      # TODO: remove sleep and then backspace sending - this is a workaround for autocomplete working
      sleep 1
      find(input_locator).native.send_keys(:backspace)
      expect(!all(options_locator).empty?).to eq(match_expected)
      first(options_locator, text: search_term).click
    end
  end
end
