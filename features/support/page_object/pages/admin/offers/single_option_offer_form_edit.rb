# frozen_string_literal: true

require_relative "../../page.rb"
require_relative "../../../components/dropdown.rb"

module AdminPages
  # /de/admin/opportunities/(:?\d+)/offer/single_column_new
  class SingleOptionOfferFormEdit
    include Page
    include Components::Dropdown

    def select_verkaufsargument_dropdown_option(option)
      first("div[data-test-consultation-selection] > div").click
      find("span[data-test-consultation-selection-option]", shy_normalized_text: option).click
    end

    def select_tarif_dropdown_option(option)
      root_locator = "div[data-test-offer-details-tarif-select]"

      find("#{root_locator} > div").click
      page.find("#{root_locator} input[type='search']", visible: true).send_keys(option)
      first("#{root_locator} ul.ember-power-select-options > li", text: /#{option}/).click
    end

    def enter_value_into_pramie_input_field(value)
      root_locator = "div[data-test-offer-details-bonus]"
      expect(page).to have_selector("#{root_locator} p.error-message", text: "Prämie muss größer als 0 sein")
      find("#{root_locator} input").set(value)
    end

    def select_zahlweise_dropdown_option(option)
      find("div[data-test-offer-details-rhythm-select] > div").click
      find("span[data-test-offer-details-rhythm-select-option]", text: option).click
    end

    def enter_value_into_coverage_features_field(label, value)
      root_locator = "div[data-test-offer-coverage-features] div.row[data-test-ui-coverage-feature]"

      find(root_locator, text: /#{label}/).find("input[data-test-ui-input-type]").set(value)
      find(root_locator, text: /#{label}/).find("div[data-test-ui-check-box] span").click
    end

    def attach_document(type)
      find("div.cucumber-documents-section div.row .label", text: type)
        .first(:xpath, ".//../..").find("input[type='file']", visible: false)
        .set(Helpers::OSHelper.upload_file_path("retirement_cockpit.pdf"))
    end

    def fill_in_coverage_features_section(coverage_features)
      return unless coverage_features.any?
      coverage_features[0].each do |feature_key, feature_value|
        key = feature_key.split.map(&:capitalize).join(" ") # capitalize every word from the key
        enter_value_into_coverage_features_field(key, feature_value)
      end
    end

    def fill_in_documents_section(document_types)
      return unless document_types.any?
      document_types.each do |document_type|
        attach_document(document_type[0])
      end
    end
  end
end
