# frozen_string_literal: true

require_relative "../../components/card.rb"
require_relative "../../components/messenger.rb"
require_relative "../../components/modal.rb"
require_relative "../page.rb"

module AppPages
  # /de/app/manager
  class Manager
    include Page
    include Components::Card
    include Components::Messenger
    include Components::Modal

    def assert_contracts_adding_options
      expect(page).to have_selector(".cucumber-add-contracts-options")
    end

    private

    # extend Components::Button ----------------------------------------------------------------------------------------

    def click_plus_button
      find(".cucumber-add-button").click
    end

    def click_rentencheck_button
      find("h1", text: "Rentencheck").click
    end

    def click_pensionscheck_button
      find("h1", text: "Pensionscheck").click
    end

    # extend Components::Card ------------------------------------------------------------------------------------------

    # TODO: This is heavy hack. Force test to specify number of card
    def contract_card(card_text)
      begin
        page.all(".cucumber-contract-card", starts_with_shy_normalized_text: card_text.gsub(" - ", " "))[0]
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        retry
      end
    end

    def assert_contract_card(option)
      expect(contract_card(option)).not_to be_nil
    end

    def assert_no_contract_card(option)
      expect(contract_card(option)).to be_nil
    end

    def click_on_contract_card(option)
      contract_card(option).click
    end

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def close_rate_us_modal
      return unless page.has_css?("#modal-overlays", wait: 1)
      find("#modal-overlays .cucumber-close-modal").click
      page.assert_no_text("Gefällt dir Clark", wait: 5)
    end

    def close_start_demand_check_modal
      find(".cucumber-demand-check-reminder-modal-close").click
      page.assert_no_text("Wie gut bist du versichert?", wait: 5)
    end

    def close_new_demand_check_modal
      find(".cucumber-modal-close").click
      page.assert_no_text("Mache mehr aus CLARK!", wait: 5)
    end

    def close_offer_modal
      find("cucumber-close-modal").click
      page.assert_no_text("Dein Angebot ist da!", wait: 5)
    end

    def assert_offer_modal
      expect(page).to have_selector(".cucumber-offer-available-modal")
    end
  end
end
