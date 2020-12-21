# frozen_string_literal: true

require_relative "../../../../components/list.rb"
require_relative "../../../page.rb"
require_relative "abstract_targeting.rb"

module AppPages
  # /de/app/mandate/targeting/selection
  class TargetingSelection < AbstractTargeting
    include Components::List

    # Page specific methods --------------------------------------------------------------------------------------------

    def assert_selected_inquiry(category, company)
      find(".cucumber-targeting-categories-selected").find("li[data-id]", shy_normalized_text: "#{category} #{company}")
    end

    # extend Components::List ------------------------------------------------------------------------------------------

    def assert_categories_list(_)
      expect(page).to have_css(".cucumber-targeting-select-categories-popular")
    end
  end
end
