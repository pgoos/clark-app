# frozen_string_literal: true

require_relative "../../../components/file_upload.rb"
require_relative "../../../components/label.rb"
require_relative "../../../components/modal.rb"
require_relative "../../../components/section.rb"
require_relative "../../../components/card.rb"
require_relative "../../page.rb"
require_relative "../../../../test_context_manager.rb"

module AppPages
  # /de/app/contracts/(:?\d+)
  class Clark2ContractDetails
    include Page
    include Components::Card
    include Components::FileUpload
    include Components::Label
    include Components::Modal
    include Components::Section

    # Page specific methods --------------------------------------------------------------------------------------------

    # Method performs assertions on contract progress bar
    # @param number [Integer] index number of a stage
    # @param state [String] expected state of a stage
    # @param title [String] expected title of a stage
    def assert_progress_bar_stage(number, state, title)
      stage = page.all("div[data-test-step]")[number - 1]
      expect(stage["data-test-step-state"]).to eq(state)
      expect(stage.text).to eq(title)
    end

    private

    # extend Components::Card ------------------------------------------------------------------------------------------

    def assert_amount_of_document_cards(amount)
      expect(all(".cucumber-document-card").length).to eq(amount)
    end

    # extend Components::Label -----------------------------------------------------------------------------------------

    def assert_contract_details_title_label(text)
      expect(page).to have_css("h1[data-test-contract-details-main-title]", text: text)
    end

    def assert_contract_details_secondary_title_label(text)
      expect(page).to have_css("h2[data-test-contract-details-secondary-title]", text: text)
    end

    def assert_waiting_period_label(_)
      expect(page).to have_css("span[data-test-waiting-time-badge]")
      expect(find("span[data-test-waiting-time-badge]").text).to match(/WARTEZEIT: \d{2} STUNDEN/)
    end

    # extend Components::Section ---------------------------------------------------------------------------------------

    def assert_clark_rating_section(_)
      expect(page).to have_css("div", text: "CLARK-Rating")
      expect(page).to have_css("div[data-test-rating]")
      expect(page).to have_css("p.cucumber-star-rating-description")
    end

    # Method asserts that tip and tricks sections exist and contains expected amount of items
    # @param items [String] Examples: 3 items, 777 items
    def assert_tips_and_info_section(items)
      expected_tips_count = items.split(" ")[0].to_i
      tips_selector = "div[data-test-tips-item]"

      expect(page).to have_css("div", text: "Tipps & Allgemeine Informationen")

      if TestContextManager.instance.mobile_browser?
        (1..expected_tips_count).each do |i|
          Helpers::MobileBrowserHelper.switch_to_slider_section(i) unless i == 1
          # on each tips page, make sure there is only one item
          expect(page.find_all(tips_selector).size).to eq(1)
        end
      else
        expect(page.find_all(tips_selector).size).to eq(expected_tips_count)
      end
    end

    def assert_third_party_contract_coverage_section(_)
      expect(page).to have_css("div", text: "Versicherungsschutz über Dritte")
      expect(page).to have_selector(".cucumber-third_party_insurance")
    end
  end
end
