# frozen_string_literal: true

require_relative "../page.rb"

module AppPages
  # /de/app/freyr
  class FreyrFunnel
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------
    def enter_customer_data_email(customer)
      find(".cucumber-freyr-email").set(customer.email)
    end
  end
end
