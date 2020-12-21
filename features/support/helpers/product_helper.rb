# frozen_string_literal: true

module Helpers
  module ProductHelper
    module_function

    def create_new_product(customer, plans)
      plans.each do |plan|
        product_attributes = generate_payload(customer, plan)
        ApiFacade.new.automation_helpers.post_create_new_product(product_attributes)
        return product_attributes[:script_params][:products][0][:attributes][:number]
      end
    end

    def generate_payload(customer, plan)
      { script_params:
            { products:
                  [
                    { attributes: {
                      plan: {
                        category_name: plan[:category_name],
                        company_name: plan[:company_name]
                      },
                        mandate_id: customer.mandate_id,
                        number: SecureRandom.uuid
                    } }
                  ] } }
    end
  end
end
