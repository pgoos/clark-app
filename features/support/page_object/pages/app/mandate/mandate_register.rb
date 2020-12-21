# frozen_string_literal: true

require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/register
  class MandateRegister
    include Page
    include Components::Label

    private

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_customer_data_password(customer)
      find(".cucumber-mandate-registration-password").set(customer.password)
    end
  end
end
