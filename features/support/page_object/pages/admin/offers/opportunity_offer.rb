# frozen_string_literal: true

require_relative "../../page.rb"

module AdminPages
  # /de/admin/opportunities/(:?\d+)/offer
  class OpportunityOffer
    include Page

    # extend Components::Text --------------------------------------------------------------------------------------
    def assert_status(expected_status)
      expect(page.all("table tr")[2].all("td")[1].text.downcase).to eq(expected_status.downcase)
    end
  end
end
