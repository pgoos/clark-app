# frozen_string_literal: true

require_relative "../../helpers/wrappers/wrappers"

module Components
  # This component is responsible for interactions with different (contract, recommendation, etc) cards
  module Card
    extend Helpers::Wrappers

    sleep_after 0.25, :click_on_card

    # Method clicks on a card
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def click_on_recommendation_card(card) { }
    # @param marker [String] custom method marker
    # @param card [String, nil] concrete card sign
    def click_on_card(marker, card=nil)
      send("click_on_#{marker.tr(' ', '_')}_card", card)
    end

    # Method asserts that card is present on a page
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_recommendation_card(card) { }
    # @param marker [String] custom method marker
    # @param card [String, nil] concrete card sign
    # @param table [Cucumber::Ast::Table, nil] if value is provided, will send table data as argument
    def assert_card(marker, card=nil, table=nil)
      if !table.nil?
        send("assert_#{marker.tr(' ', '_')}_card", table)
      else
        send("assert_#{marker.tr(' ', '_')}_card", card)
      end
    end

    # Method asserts that card is not present on a page
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_no_recommendation_card(card) { }
    # @param marker [String] custom method marker
    # @param card [String, nil] concrete card sign
    def assert_no_card(marker, card=nil)
      send("assert_no_#{marker.tr(' ', '_')}_card", card)
    end

    # Method asserts that a card contains
    # a certain text property
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_importance_label_property_of_card{ }
    # @param marker [String] custom method marker
    # @param card [String] card name
    # @param text [String] text to verify in property
    def assert_property_of_card(marker, card, text)
      send("assert_#{marker.tr(' ', '_')}_property_of_card", card, text)
    end

    # The method asserts that the amount of cards of a certain type is equal to the expected
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_amount_of_uploaded_documents_cards(amount) { }
    # @param marker [String] custom method marker
    # @param amount [Integer] expected amount of cards
    def assert_amount_of_cards(marker, amount)
      send("assert_amount_of_#{marker.tr(' ', '_')}_cards", amount)
    end

    # The method asserts that the amount of cards of a certain type is equal to the expected
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_retirement_card_is_not_clickable(card) { }
    # @param marker [String] custom method marker
    # @param card [String] card name
    def assert_card_is_not_clickable(marker, card)
      send("assert_#{marker.tr(' ', '_')}_card_is_not_clickable", card)
    end

    # Method clicks link on card
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def click_property_on_recommendation_card(text, card) { }
    # @param property_marker [String] property css marker
    # @param marker [String] custom method marker
    # @param card_title [String, nil] specific card title
    def click_property_on_card(property_marker, marker, card_title)
      send("click_property_on_#{marker.tr(' ', '_')}_card", property_marker, card_title)
    end

    private

    # cross-page shared methods ----------------------------------------------------------------------------------------

    # method clicks on the recommendation card
    # @param recommendation_card [String] concrete card sign
    def click_on_recommendation_card(recommendation_card)
      # fetching the parent element, which contains h1 and span
      card = find("[data-cucumber-recommendation-card-title='#{recommendation_card}']").find(:xpath, "..")
      return card.all("h1")[0].click unless card.all("h1").empty?
      return card.all("span")[0].click unless card.all("span").empty?
      raise Capybara::ElementNotFound.new("Can't click on '#{recommendation_card}' recommendation card")
    end

    # Method asserts that page contains expected amount of uploaded document cards
    # @param amount [Integer] expected amount of document cards
    def assert_amount_of_uploaded_document_cards(amount)
      Helpers::MobileBrowserHelper.open_section_if_required("Dokumente")
      actual_docs_number = find(".cucumber-document-upload").all(".cucumber-uploaded-document-card").length
      expect(actual_docs_number).to eq(amount)
    end
  end
end
