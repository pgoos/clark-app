# frozen_string_literal: true

require_relative "../page.rb"

module AppPages
  # /de/app/customer/account/reset-password
  class ResetPassword
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------
    def enter_customer_data_email(customer)
      fill_in "E-Mail Adresse", with: customer.email
    end
  end
end
