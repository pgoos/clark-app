# frozen_string_literal: true

require_relative "../../page.rb"

module AppPages
  # /de/app/contracts/customer/registration
  class Clark2Registration
    include Page

    EMAIL_INPUT_CSS = 'input[type="email"]'
    PASSWORD_INPUT_CSS = 'input[type="password"]'

    # extend Components::Input -----------------------------------------------------------------------------------------

    def assert_email_address_input_field
      expect(page).to have_css(EMAIL_INPUT_CSS)
    end

    def assert_password_input_field
      expect(page).to have_css(PASSWORD_INPUT_CSS)
    end

    def enter_customer_data_email_address(customer)
      page.find(EMAIL_INPUT_CSS).send_keys(customer.email)
    end

    def enter_customer_data_password(customer)
      page.find(PASSWORD_INPUT_CSS).send_keys(customer.password)
    end
  end
end
