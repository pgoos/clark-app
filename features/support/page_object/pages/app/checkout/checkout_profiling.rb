# frozen_string_literal: true
require_relative '../mandate/abstract_profiling'

require_relative "../../../components/checkout_stepper.rb"

module AppPages
  class CheckoutProfiling < AbstractProfiling
    include Components::CheckoutStepper

    def fill_profiling_form(customer)
      super
      choose("Herr", allow_label_click: true, visible: false)
      set_field_value("phone-number", customer.phone_number)
      sleep 0.25
    end
  end
end
