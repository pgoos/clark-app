# frozen_string_literal: true

require_relative "../../page.rb"

class MandatesPage
  include Page

    def click_on_mandate_id(customer)
      table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
      table_helper.click_by_text_in_row(0, 4, customer.email)
    end

    def assert_mandate_label_in_table(customer, mandate_label)
      table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
      mandate_row_number = table_helper.find_row_number_by_text(customer.email)
      mandate_row = table_helper.row(mandate_row_number)
      mandate_row.first("span", class: "cucumber-badge-customer", text: mandate_label, wait: 1)
    end

  def click_on_mandate_id_by_source(source)
    table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
    table_helper.click_by_text_in_row(0, 1, source)
  end
end
