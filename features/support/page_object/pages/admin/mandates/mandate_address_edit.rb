# frozen_string_literal: true

require_relative "../../page.rb"
require_relative "../../../components/checkbox.rb"
require_relative "../../../components/form.rb"

module AdminPages
  # /de/admin/mandates/(:?\d+)/addresses/(:?\d+)/edit
  class MandateAddressEdit
    include Page
    include Components::Checkbox
    include Components::Form

    def select_accept_rules_checkbox
      find("#send_notification").click
    end

    def fill_out_address_edit_form(form_attributes)
      enter_value_into_address_street_input_field(form_attributes[:street])
      enter_value_into_address_house_input_field(form_attributes[:house_number])
      enter_value_into_address_plz_input_field(form_attributes[:plz])
      enter_value_into_address_plz_input_field(form_attributes[:city])
    end

    def enter_value_into_address_street_input_field(street_name)
      enter_value_into("street", street_name) unless street_name.nil?
    end

    def enter_value_into_address_house_input_field(house_number)
      enter_value_into("house_number", house_number) unless house_number.nil?
    end

    def enter_value_into_address_plz_input_field(plz)
      enter_value_into("zipcode", plz) unless plz.nil?
    end

    def enter_value_into_address_city_input_field(city)
      enter_value_into("city", city) unless city.nil?
    end

    def click_update_button
      find("aktualisieren").click
    end

    private

    def enter_value_into(field_name, value)
      find("input[name*='address[#{field_name}]']").set(value)
    end
  end
end
