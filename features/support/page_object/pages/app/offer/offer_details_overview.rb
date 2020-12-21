# frozen_string_literal: true

require_relative "../../../components/list.rb"
require_relative "../../../components/radio_button.rb"
require_relative "../../../components/checkbox.rb"
require_relative "../../../components/scroll.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/offer/(:?\d+)/data/(\d+)
  class OfferDetailsOverview
    include Page
    include Components::List
    include Components::RadioButton
    include Components::Checkbox
    include Components::Scroll

    private

    # extend Components::List ------------------------------------------------------------------------------------------

    def assert_documents_list(table)
      actual = find("ol.cucumber-offer-checkout-documents-list").all("li a").map(&:text)
      expect(actual).to eq(table.rows.flatten)
    end

    # extend Components::RadioButton -----------------------------------------------------------------------------------

    def select_read_application_documents_radio_button(option)
      return find(".cucumber-offer-checkout-read-documents-radio-button").click if option == "yes"
      raise NotImplementedError.new
    end

    def select_consent_radio_button(option)
      return find(".cucumber-offer-checkout-consent-radio-button").click if option == "yes"
      raise NotImplementedError.new
    end
  end
end
