# frozen_string_literal: true

require_relative "../../../../components/card.rb"
require_relative "../../../../components/option.rb"
require_relative "../../../page.rb"

module AppPages
  # /de/app/contracts/create
  # @abstract
  class Clark2CreateContract
    include Page
    include Components::Card
    include Components::Option

    SEARCH_INPUT_FILED_CSS = "div[data-test-generic-selection-search] input"

    private

    # extend Components::Input -----------------------------------------------------------------------------------------

    def assert_search_input_field
      expect(page).to have_css(SEARCH_INPUT_FILED_CSS)
    end

    def enter_value_into_search_input_field(value)
      find(SEARCH_INPUT_FILED_CSS).send_keys(value)
    end

    # extend Components::Card ------------------------------------------------------------------------------------------

    def click_on_popular_option_card(card_text)
      find("div.cucumber-popular-item p", shy_normalized_text: card_text).click
    end

    # extend Components::Option ----------------------------------------------------------------------------------------

    def select_search_result_option(option, _)
      find("div[data-test-generic-selection-list-item]", shy_normalized_text: option).click
    end
  end
end
