# frozen_string_literal: true

require_relative "../../../components/icon.rb"
require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/phone-verification
  class PhoneVerification
    include Page
    include Components::Icon
    include Components::Label

    private

    # extend Components::Icon ------------------------------------------------------------------------------------------

    def assert_trust_icons(icons_quantity)
      icons = find(".cucumber-trust-icons").all(".cucumber-trust-icon")
      expect(icons.length).to be(icons_quantity)
      icons.each { |icon| icon.should be_visible }
    end

    # extend Components::Input -----------------------------------------------------------------------------------------

    def enter_customer_data_phone_number(customer)
      find(".cucumber-phone-input").set(customer.phone_number)
    end

    # extend Components::Label -----------------------------------------------------------------------------------------
    def assert_country_code_label(dialing_code)
      country_code = find(".cucumber-phone-verification-dialing-code").text
      expect(dialing_code).to eq(country_code)
    end
  end
end
