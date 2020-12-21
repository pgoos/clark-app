# frozen_string_literal: true

module Helpers
  module OfferHelper
    module_function

    def create_new_offer(customer)
      # ApiFacade.new.automation_helpers.post_create_new_offer(customer["customer"]["id"],
      ApiFacade.new.automation_helpers.post_create_new_offer(customer.mandate_id,
                                                             category_name)
    end
  end
end
