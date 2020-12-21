# frozen_string_literal: true

require_relative "../../../components/checkbox.rb"
require_relative "../../../components/checkout_stepper.rb"

module AppPages
  # /de/app/offers/(:?\d+)/checkout/(:?\d+)/payment-details
  class CheckoutPaymentDetails
    include Page
    include Components::CheckoutStepper
    include Components::Checkbox

    private

    # extend Components::Checkbox --------------------------------------------------------------------------------------

    def select_reassurance_checkbox
      page.find_field("consent").find(:xpath, "..").click
    end

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_customer_data_iban(customer)
      page.find_field("iban").send_keys(customer.iban.delete(" "))
      sleep 0.25
    end
  end
end
