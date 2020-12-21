# frozen_string_literal: true

require_relative "../page.rb"

module AppPages
  # /de/app/login
  class AppLogin
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------
    def enter_customer_data_email(customer)
      fill_in "mandate_login_email", with: customer.email
    end
  end
end
