# frozen_string_literal: true

require_relative "../../page.rb"

class NewOpportunityWithProspectPage
  include Page

    def enter_customer_data(customer)
      fill_in "opportunity_mandate_attributes_first_name", with: customer.first_name
      fill_in "opportunity_mandate_attributes_last_name", with: customer.last_name
      fill_in "opportunity_mandate_attributes_birthdate", with: customer.birthdate
      fill_in "opportunity_mandate_attributes_lead_attributes_email", with: customer.email
      fill_in "opportunity_mandate_attributes_active_address_attributes_street", with: customer.address_line1
      fill_in "opportunity_mandate_attributes_active_address_attributes_house_number", with: customer.house_number
      fill_in "opportunity_mandate_attributes_active_address_attributes_zipcode", with: customer.zip_code
      fill_in "opportunity_mandate_attributes_active_address_attributes_city", with: customer.place
    end

    def select_category(category)
      Helpers::OpsUiHelper.select_combobox_option("opportunity_category_id", category)
    end

    def assert_category_dropdown(category_name)
      expect(page).to have_css("#opportunity_category_id_chosen a", text: category_name)
    end
end
