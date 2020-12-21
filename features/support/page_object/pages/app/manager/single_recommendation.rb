# frozen_string_literal: true

require_relative "../../../components/image.rb"
require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/manager/categories/(:?\d+)
  class SingleRecommendation
    include Page
    include Components::Label
    include Components::Image

    # Page specific methods --------------------------------------------------------------------------------------------

    def assert_quality_standard(icons_quantity)
      expect(page).to have_selector(".cucumber-quality-standards-title", text: "Clark-Qualitätsstandards")
      expect(page).to have_selector(".cucumber-quality-standards-main-icon")
      icons = find(".qs-stats__features").all(".cucumber-quality-standards-icon", visible: true)
      expect(icons.length).to be(icons_quantity)
      expect(page).to have_selector(".cucumber-quality-standards-stats")
    end

    def assert_why_clark_footer_section(table)
      elems = find(".capybara-category-details-clark-service").all("h1, h2, p")
      actual = elems.map(&:text)
      expect(actual).to eq(table.rows.flatten)
    end

    private

    # extend Components::Label -----------------------------------------------------------------------------------------

    def assert_category_title_label(category)
      expect(page).to have_css("h1.cucumber-manager-category-title", shy_normalized_text: category)
    end

    # method validates importance tag label in recommendation page info
    # @param importance [String] importance level
    def assert_category_importance_tag_label(importance)
      if importance.nil?
        expect(page).to have_selector(".cucumber-category-title-importance")
      else
        expect(page).to have_css(".cucumber-category-title-importance", shy_normalized_text: importance)
      end
    end
  end
end
