# frozen_string_literal: true

require_relative "../../page.rb"

class MandatesBusinessEventsPage
  include Page

  def assert_update_address_metadata(cell_text, column_number, row_number)
    expect(address_metadata_table_helper.cell_text(row_number - 1, column_number - 2)).to include(cell_text)
  end

  private

  def events_table_helper
    # find table with general information
    business_events_table = find("table.table.table-hover.table-bordered", visible: true)
    Helpers::OpsUiHelper::TableHelper.new(node: business_events_table)
  end

  def address_metadata_table_helper
    # get_row_with updated_address_info (always next to row with "update_address" text)
    address_metadata_info_row = events_table_helper.row(events_table_helper.find_row_number_by_text("update_address"))

    # find nested table
    Helpers::OpsUiHelper::TableHelper.new(node: address_metadata_info_row)
  end
end
