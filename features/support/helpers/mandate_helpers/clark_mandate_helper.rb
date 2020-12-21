# frozen_string_literal: true

require "luhn"
require "ibandit"

require_relative "mandate_helper"

module Helpers
  module MandateHelpers
    class ClarkMandateHelper < MandateHelper
      def generate_mandate(customer=nil)
        customer = super(customer)
        customer.payback_code = Luhn.generate(16, prefix: "308342") if customer.source == "payback"
        customer.order_number = "100#{7.times.map{rand(7)}.join}" if customer.source == "home24"
        customer
      end

      # TODO: Implement more generic solution JCLARK-61902
      def default_inquiries
        [["Rechtsschutzversicherung", "Allianz Versicherung"]]
      end

      def set_faker_locale
        Faker::Config.locale = "de"
      end

      def generate_iban
        @customer.iban = Ibandit::IBAN.new(
          country_code: "DE",
          bank_code: "50010517", # dummy DE bank_code
          account_number: Faker::Bank.account_number
        ).iban
      end
    end
  end
end
