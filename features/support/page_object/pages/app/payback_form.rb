# frozen_string_literal: true

require_relative "../page.rb"
require_relative "../generic_page.rb"
require_relative "../../components/icon.rb"


module AppPages
  # /cms/payback
  class PaybackForm
    include Page
    include Components::Icon

    # extend Components::Input -----------------------------------------------------------------------------------------
    def assert_payback_input_field
      expect(page).to have_css(".cucumber-kunden-number", wait: 3)
    end

    def click_payback_icon(_)
      find(".cucumber-payback-tooltip").click
    end

    def enter_value_into_payback_input_field(value)
      find(".cucumber-kunden-number").set(value)
    end

    def enter_customer_data_payback_code(customer)
      find(".cucumber-kunden-number").set(customer.payback_code)
    end
  end
end
