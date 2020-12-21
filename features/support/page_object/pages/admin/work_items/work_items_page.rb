# frozen_string_literal: true

require_relative "../../page.rb"

class WorkItemsPage
  include Page

  def assert_customer_is_not_in_table(customer)
    begin
      working_items_table.find_row_number_by_text((customer.first_name + " " + customer.last_name).to_s)
      customer_is_found = true
    rescue Capybara::ElementNotFound
      customer_is_found = false
    end
    expect(customer_is_found).to equal false
  end

  def assert_customer_is_in_table(customer)
    sleep 1 # TODO: Find better solution. Seems like table is not fully loaded before the assertion executes
    expect(working_items_table.find_row_number_by_text((customer.first_name + " " + customer.last_name).to_s))
      .not_to eq(0)
  end

  def click_address_change_id_by(customer)
    customer_row = working_items_table.find_row_number_by_text((customer.first_name + " " + customer.last_name).to_s)
    working_items_table.link(customer_row, 0).click
  end

  def click_on_contract_id(contract_id)
    working_items_table.click_by_text_in_row(0, 0, contract_id)
  end

  def assert_table_is_not_empty
    expect(working_items_table.rows_number).not_to eq(0)
  end

  def assert_id_present_in_table(id)
    expect { working_items_table.find_row_number_by_text(id) }.not_to raise_error
  end

  def assert_id_is_not_present_in_table(id)
    expect { working_items_table.find_row_number_by_text(id) }.to raise_error("Row with provided text was not found")
  end

  def click_button_in_table(id, button_name)
    contract_row = working_items_table.row(working_items_table.find_row_number_by_text(id))
    if button_name == "Rückfrage"
      contract_row.find("a", text: "Rückfrage", match: :prefer_exact).click
    elsif button_name == "thumbs up"
      accept_confirm do
        contract_row.find(".move-to-success", match: :first).click
      end
    else
      raise ArgumentError.new("One of three options is required - Rückfrage or thumbs up")
    end
  end

  private

  # Sometimes there is only single node in DOM
  # A quick fix would be to proceed as before if 2 nodes were found or go with the first node if only one is found
  def working_items_table
    contract_info_tables = page.all("table.table-hover.table-bordered.table-striped", visible: true)
    unless contract_info_tables[1].nil?
      return Helpers::OpsUiHelper::TableHelper.new(node: contract_info_tables[1])
    end
    Helpers::OpsUiHelper::TableHelper.new(node: contract_info_tables[0])
  end
end
