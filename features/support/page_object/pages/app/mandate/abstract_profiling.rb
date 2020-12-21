# frozen_string_literal: true

require_relative "../../../components/label.rb"
require_relative "../../page.rb"

module AppPages
  # /de/app/mandate/profiling
  # /de/app/customer/upgrade/profile
  # /de/app/offers/(:?\d+)/checkout/(:?\d+)/profile
  class AbstractProfiling
    include Page
    include Components::Label

    # Page specific methods ----------------------------------------------------------------
    # TODO: transform these methods to component' methods
    def assert_field_value(field_name, expected_value)
      expect(find(".cucumber-profile-customer-#{field_name}").value).to eq(expected_value)
    end

    def assert_gdpr_acceptance_date(date)
      expect(find("p.cucumber-gdpr-str").text).to end_with(date)
    end

    def fill_profiling_form(customer)
      set_field_value("first-name",   customer.first_name)
      set_field_value("last-name",    customer.last_name)
      set_field_value("birth-date",   customer.birthdate)
      set_field_value("street-name",  customer.address_line1)
      set_field_value("house-number", customer.house_number)
      set_field_value("post-code",    customer.zip_code)
      set_field_value("city-name",    customer.place)
      sleep 0.25
    end

    def set_field_value(field_name, value)
      find(".cucumber-profile-customer-#{field_name}").set(value)
    end

    private

    # extend Components::Link ------------------------------------------------------------------------------------------

    def assert_mandate_document_link_is_not_visible
      page.assert_no_selector(".cucumber-profiling-maklerpdf")
    end

  end
end
