# frozen_string_literal: true

require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/retirement/categories/(:?.+)
  class RetirementSingleRecommendation
    include Page
    include Components::Label

    # Page specific methods --------------------------------------------------------------------------------------------

    def assert_statistics_map
      expect(page).to have_selector(".cucumber-category-map")
    end

    private

    # extend Components::Label -----------------------------------------------------------------------------------------

    def assert_category_importance_tag_label(_)
      expect(page).to have_selector(".cucumber-category-title-importance")
    end
  end
end
