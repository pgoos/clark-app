# frozen_string_literal: true

require_relative "../../page.rb"

class AppointmentsPage
  include Page

  def click_on_appointments_id(customer)
    table_helper = Helpers::OpsUiHelper::TableHelper.new(table_class: "table.table.table-hover.table-bordered")
    table_helper.click_by_text_in_row(0, 1, "#{customer.first_name} #{customer.last_name}")
  end
end
