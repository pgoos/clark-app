# frozen_string_literal: true

require_relative "mandate_helper"
require "ibandit"

module Helpers
  module MandateHelpers
    class AustriaMandateHelper < MandateHelper
      # TODO: Implement more generic solution JCLARK-61902
      def default_inquiries
        [%w[Rechtsschutzversicherung Allianz]]
      end

      def set_faker_locale
        Faker::Config.locale = "de-AT"
      end

      def generate_iban
        @customer.iban = Ibandit::IBAN.new(
          country_code: "AT",
          bank_code: "19043", # dummy AT bank_code
          account_number: Faker::Bank.account_number
        ).iban
      end
    end
  end
end
