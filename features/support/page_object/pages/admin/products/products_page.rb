# frozen_string_literal: true

require "securerandom"
require_relative "../../page.rb"

class ProductsPage
  include Page

  def click_on_product_id(product_number)
    table_helper.click_by_text_in_row(0, 0, product_number)
  end

  # not using table helper here due to ambiguous match on the mandate details page
  def click_on_first_product
    Helpers::OpsUiHelper::TableHelper.new(parent_id: "products").link(0, 0).click
  end

  private

  def table_helper
    @table_helper ||= Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
  end
end
