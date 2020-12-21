# frozen_string_literal: true

require_relative "../../../components/modal.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/offer/(:?\d+)
  class OfferView
    include Page
    include Components::Modal

    private

    # extend Components::Button ----------------------------------------------------------------------------------------

    def click_bestellen_button
      find(".cucumber-offer-details-bestellen-button", match: :first).click
    end

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def assert_offer_modal
      expect(page).to have_selector(".cucumber-offer-available-modal")
    end
  end
end
