# frozen_string_literal: true

require_relative "../../page.rb"

class OpportunityDetailsPage
  include Page

  def assert_appointment_rows_number(row_count)
    expect(appointment_table_helper.rows_number).to equal(row_count)
  end

  def assert_appointment_table_data(cell_text, column_number, row_number)
    expect(appointment_table_helper.cell_text(row_number - 1, column_number - 1)).to include(cell_text)
  end

  def assert_status(status)
    first("div", text: "Ereignisse", wait: 1).first("span", text: status)
  end

  private

  def general_info_table_helper
    # find table with general information
    general_info_table = find("table.table-bordered.table-hover.table-resource", visible: true)
    Helpers::OpsUiHelper::TableHelper.new(node: general_info_table)
  end

  def appointment_table_helper
    # find line number or the row with "Termine" text
    appointment_line_number = general_info_table_helper.find_row_number_by_text("Termine")

    # get_row_with appointment_info (always next to row with "Termine" text)
    appointment_info_row = general_info_table_helper.row(appointment_line_number + 1)

    # find nested table
    Helpers::OpsUiHelper::TableHelper.new(node: appointment_info_row)
  end
end
