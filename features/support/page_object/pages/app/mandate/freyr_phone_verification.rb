# frozen_string_literal: true

require_relative "../../page.rb"
require_relative "phone_verification.rb"

module AppPages
  # /de/app/freyr/phone-verification
  class FreyrPhoneVerification < PhoneVerification
    include Page

    private

    def enter_customer_data_phone_number(customer)
      find(".cucumber-phone-number-input").set(customer.phone_number)
    end
  end
end
