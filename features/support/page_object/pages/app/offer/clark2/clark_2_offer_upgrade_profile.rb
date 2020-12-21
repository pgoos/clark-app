# frozen_string_literal: true

require_relative "../../mandate/abstract_profiling.rb"

module AppPages
  # /de/app/customer/upgrade/profile
  class Clark2OfferUpgradeProfile < AbstractProfiling
    # Page specific methods --------------------------------------------------------------------------------------------
    # TODO: transform these methods to component' methods
    def fill_profiling_form(customer)
      super
      choose("Herr", allow_label_click: true, visible: false)
      set_field_value("phone-number", customer.phone_number)
      sleep 0.25
    end
  end
end
