# frozen_string_literal: true

require_relative "../../../components/card.rb"
require_relative "../../../components/icon.rb"
require_relative "../../../components/modal.rb"
require_relative "../../page.rb"
require_relative "../../../../test_context_manager.rb"

module AppPages
  # /de/app/manager/recommendations
  class Recommendations
    include Page
    include Components::Card
    include Components::Modal

    CARD_LOCATOR = "[data-cucumber-recommendation-card-title]"

    INSURANCE_CATEGORIES = {
      "Besitz & Eigentum" => "things",
      "Gesundheit & Existenz" => "health",
      "Altersvorsorge" => "retirement"
    }.freeze

    private_constant :INSURANCE_CATEGORIES

    # Page specific methods --------------------------------------------------------------------------------------------

    # assert count in rings update on adding a new recommended category as inquiry
    def assert_numbers_in_recommendations_rings(text, marker)
      expect(find("[data-ring-id='#{marker}']")).to have_text(text)
    end

    # TODO: move this methods to Components::Card ?
    def assert_recommendation_cards(exp_categories)
      exp_categories_array = exp_categories.split("~")
      cards_count = 0

      INSURANCE_CATEGORIES.each do |type|
        current_tab_card_count = page.find_all(CARD_LOCATOR).size
        cards_count = current_tab_card_count
        exp_categories_array.select { |cat| Repository::InsuranceCategories[cat] == type }.each do |exp_cat_of_type|
          assert_recommendation_card(exp_cat_of_type)
        end
      end

      # Check that number of recommendations is correct. By checking this and that we see all intended recommendations
      # we are ensuring that no additional categories are recommended
      expect(cards_count).to eq(exp_categories_array.length)
    end

    def assert_recommendation_card(category)
      demand_category = Repository::InsuranceCategories[category]
      demand_category_selector = ["[data-cucumber-recommendations-listing='#{demand_category}']",
                                  "[data-cucumber-recommendation-card-title]"].join(" ")
      expect(page).to have_css(demand_category_selector, shy_normalized_text: category)
    end

    private

    # extend Components::Card ------------------------------------------------------------------------------------------

    def assert_no_recommendation_card(category)
      expect(page).not_to have_selector(".cucumber-recommendation-card-title", text: category, wait: 5)
    end

    # method validates importance label of a specific recommendation card
    # @param card_title [String] card title
    # @param importance [String] expected importance level
    def assert_importance_label_property_of_card(card_title, importance)
      card = find("[data-cucumber-recommendation-card-title='#{card_title}']").find(:xpath, "..")
      expect(card).to have_css("span", shy_normalized_text: importance)
    end

    # method clicks on the specified property of a specific recommendation card
    # @param property_marker[String] property on the card that's interacted with
    # @param card_title[String] title of the recommendation card
    def click_property_on_recommendation_card(property_marker, card_title)
      find("[data-cucumber-#{property_marker.tr(' ', '_')}-link='#{card_title}']").click
    end

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def close_first_recommendation_modal
      # without the delay, test is very inconsistent, even with the custom css selector
      sleep 2
      find("[data-cucumber-modal-close]").click
      page.assert_no_text("Kaum einer ist sie", wait: 5)
    end

  end
end
