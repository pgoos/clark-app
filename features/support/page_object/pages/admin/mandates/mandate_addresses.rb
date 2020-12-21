# frozen_string_literal: true

require_relative "../../page.rb"

module AdminPages
  # /de/admin/mandates/(:?\d+)/addresses
  class MandateAddresses
    include Page

    def find_request_by_position(position)
      validate_position(position) do |valid_position|
        change_requests_table.row(valid_position)
      end
    end

    def click_request_by_position(position)
      validate_position(position) do |valid_position|
        change_requests_table.link(valid_position - 1, 0).click
      end
    end

    # asserts
    def assert_requests_count(requests_count)
      expect(change_requests_table.rows_number).to equal(requests_count)
    end

    private

    def validate_position(position)
      raise ArgumentError.new("Invalid position, should be <= 0") if position <= 0
      yield position
    end

    def change_requests_table
      Helpers::OpsUiHelper::TableHelper.new(node: find("table.table-hover.table-bordered", visible: true))
    end
  end
end
