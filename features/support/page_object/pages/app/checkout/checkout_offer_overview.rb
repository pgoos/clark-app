# frozen_string_literal: true

require_relative "../../../components/checkout_stepper.rb"

module AppPages
  # /de/app/offers/(:?\d+)/checkout/(:?\d+)/summary
  class CheckoutOfferOverview
    include Page
    include Components::CheckoutStepper
  end
end
