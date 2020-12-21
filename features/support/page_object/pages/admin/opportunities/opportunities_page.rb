# frozen_string_literal: true

require_relative "../../page.rb"

class OpportunitiesPage
  include Page

    def click_on_opportunity_id(customer)
      table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
      table_helper.click_by_text_in_row(0, 2, customer.email)
    end
end
