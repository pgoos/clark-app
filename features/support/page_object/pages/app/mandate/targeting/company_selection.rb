# frozen_string_literal: true

require_relative "../../../page.rb"
require_relative "abstract_targeting.rb"

module AppPages
  # /de/app/mandate/targeting/company/(:?\d+)
  class CompanySelection < AbstractTargeting

    # Page specific methods --------------------------------------------------------------------------------------------

    # TODO: transform it to label search
    def assert_company_targeting_path(category)
      expect(page).to have_css("p.cucumber-targeting-insurance-intro", starts_with_shy_normalized_text: category)
    end

    def assert_search_results
      expect(page).to have_css(".cucumber-targeting-companies-section")
    end
  end
end
