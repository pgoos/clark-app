# frozen_string_literal: true

require_relative "../../page.rb"

module CMSPages
  # /de/account/edit
  class AccountEdit
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_customer_data_email(customer)
      fill_in "user_email", with: customer.email
    end

    def enter_customer_data_password(customer)
      fill_in "user_password", with: customer.password
    end
  end
end
