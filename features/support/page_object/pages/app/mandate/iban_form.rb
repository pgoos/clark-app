# frozen_string_literal: true

require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/iban
  class IbanForm
    include Page

    private

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_customer_data_iban(customer)
      page.find("input#iban").send_keys(customer.iban.delete(" "))
      sleep 0.25
    end
  end
end
