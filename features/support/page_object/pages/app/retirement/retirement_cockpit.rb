# frozen_string_literal: true

require_relative "../../../components/card.rb"
require_relative "../../../components/modal.rb"
require_relative "../../page.rb"
require_relative "../../../components/image.rb"

module AppPages
  # /de/app/retirement/cockpit
  class RetirementCockpit
    include Page
    include Components::Card
    include Components::Modal
    include Components::Image

    private

    # extend Components::Button ----------------------------------------------------------------------------------------

    def click_produkte_hinzufugen_button
      find(".cucumber-add-button", match: :first).click
    end

    # extend Components::Card ------------------------------------------------------------------------------------------
    def assert_recommendation_card(table)
      categories = page.all("[data-cucumber-recommendation-card-title]")
      expect(table.rows.flatten).to match_array(categories.map(&:shy_normalized_text))
    end

    def assert_retirement_card(product_name)
      find(".cucumber-retirement-card", visible: true, text: product_name)
    end

    def assert_scheduled_appointment_card(_)
      expect(page).to have_css("div[data-test-retirement-overview-appointment]")
    end

    def click_on_appointment_card(_)
      # IE compatibility hook: click directly on the description text
      find(".cucumber-appointment-card", visible: true).find("p").click
    end

    def click_on_retirement_product_card(product_name)
      find(".cucumber-retirement-card", text: product_name).all("span", text: product_name)[0].click
    end

    def assert_retirement_card_is_not_clickable(card)
      page.assert_no_selector('div[role="button"]', text: card)
    end

    # extend Components::Modal -----------------------------------------------------------------------------------------

    def close_retirement_appointment_modal
      Helpers::NavigationHelper.wait_for_resources_downloaded
      find("button.cucumber-modal-close", visible: true).click
      page.assert_no_text("Direkt einen Termin vereinbaren!", wait: 5)
    end

    # extend Components::Image ------------------------------------------------------------------------------------------

    def assert_consultant_image
      expect(page).to have_selector("img.cucumber-consultant-retirement-photo")
    end

    def assert_not_to_have_consultant_image
      expect(page).not_to have_selector("img.cucumber-consultant-retirement-photo")
    end
  end
end
