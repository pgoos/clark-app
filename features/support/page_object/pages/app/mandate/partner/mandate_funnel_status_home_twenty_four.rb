# frozen_string_literal: true

require_relative "../confirming.rb"
require_relative "../mandate_funnel_status.rb"
module AppPages
  # /de/app/mandate/status
  class MandateFunnelStatusHomeTwentyFour < MandateFunnelStatus
    # Page specific methods --------------------------------------------------------------------------------------------

    # Method asserts list of registration steps on Home24 mandate status page
    # @param table [Cucumber::Ast::Table] table of expected steps
    def assert_order_number_input_field
      expect(page).to have_css(".cucumber-home24-order-number")
    end

    def enter_value_into_home24_input_field(value)
      find(".cucumber-home24-order-number").set(value)
    end

    def enter_customer_data_home24_code(customer)
      find(".cucumber-home24-order-number").set(customer.order_number)
    end
  end
end
