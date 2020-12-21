# frozen_string_literal: true

require_relative "clark_2_create_contract"

module AppPages
  # /de/app/contracts/create/category
  class Clark2SelectCategory < Clark2CreateContract
    private

    # extend Components::Card ------------------------------------------------------------------------------------------

    # @param exp_card_content [String] expected card content. Lines should be separated by " - "
    def assert_contract_card(exp_card_content)
      exp_card_content = exp_card_content.split(" - ")
      page.all("div.cucumber-base-card").each do |card|
        card_lines = card.all("p")
        next if card_lines.length != 2
        return nil if card_lines[0].text == exp_card_content[0] &&
                                            card_lines[1].shy_normalized_text == exp_card_content[1]
      end
      raise Capybara::ElementNotFound.new("Contract card '#{exp_card_content}' was not found")
    end
  end
end
