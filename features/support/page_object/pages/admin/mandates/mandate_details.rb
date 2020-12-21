# frozen_string_literal: true

require_relative "../../page.rb"
require_relative "../../../components/dropdown.rb"

# TODO: make this class stateless. @docs_number should be stored in steps definitions

module AdminPages
  class MandateDetails
    include Page
    include Components::Dropdown
    include Components::Button

    def set_products_number
      @number_of_products = number_of_products
    end

    def assert_products_num_increased
      expect(number_of_products).to eq(@number_of_products + 1)
    end

    def assert_new_product_is_in_table(new_product_number)
      first_number = Helpers::OpsUiHelper::TableHelper.new(parent_id: "products").link_text(0, 0)
      expect(first_number).to eq(new_product_number)
    end

    def assert_comment_message_input
      expect(page).to have_css("#comment_message")
    end

    def assert_mandate_label(mandate_label)
      first("span", class: "cucumber-badge-customer", text: mandate_label, wait: 1)
    end

    def assert_locked_points(points)
      table_class = "table.table-bordered.table-hover.cucumber-payback-section"
      locked_points = Helpers::OpsUiHelper::TableHelper.new(table_class: table_class).cell_text(0, 1)
      expect(locked_points).to eq(points)
    end

    def assert_latest_document_name(document_name)
      expect(first("div#interactions-list .card-body").shy_normalized_text).to eq(document_name)
    end

    def click_forward_latest_document
      first("div#interactions-list .card-body .pull-right").click
    end

    def assert_document_in_inquiry(document_name)
      first_document = find(:xpath, "//*[@id='document-details']/table/tbody").all("tr")[0].all("td")[2]
      expect(first_document.shy_normalized_text).to eq(document_name)
    end

    def click_address_change_button
      find(".edit-button").click
    end

    private

    # TODO: refactor this
    def select_type_dropdown_option(option)
      dropdown = find(".select_document_topics")
      dropdown.all("option").each_with_index do |item, index|
        next unless item.shy_normalized_text.include?(option)
        return dropdown.find(:xpath, "option[#{index + 1}]").select_option
      end
      raise Capybara::ElementNotFound.new("Option '#{option}' was not found in Type dropdown")
    end

    def number_of_products
      Helpers::OpsUiHelper::TableHelper.new(parent_id: "products").rows_number
    end
  end
end
