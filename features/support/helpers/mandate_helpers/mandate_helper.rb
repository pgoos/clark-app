# frozen_string_literal: true

require_relative "mandate_registrar"

module Helpers
  module MandateHelpers
    # Abstract Class
    # noinspection RubyNilAnalysis
    class MandateHelper
      include MandateRegistrar

      # @abstract
      def generate_mandate(customer=nil)
        # init
        set_faker_locale
        @customer = customer.nil? ? Model::Customer.new : customer

        # generate data
        generate_name
        generate_birth_date
        generate_address
        generate_credentials
        generate_iban
        generate_invitee_email
        # reset state and return result
        result = @customer.dup
        @customer = nil
        result
      end

      # TODO: re-write this method
      def update_customer_attribute(customer, value, attribute)
        attribute = attribute.downcase
        if value.casecmp("random generated value").zero?
          if attribute == "email"
            email = "test_automation_#{SecureRandom.uuid.delete('-')}"
            customer.email = Faker::Internet.email(email)
          end
          customer.password = "Test1234" if attribute == "password"
        else
          customer.send("#{attribute}=", value)
        end
      end

      private

      # @abstract
      def default_inquiries
        raise NotImplementedError.new
      end

      # @abstract
      def set_faker_locale
        raise NotImplementedError.new
      end

      def generate_name
        @customer.first_name = Faker::Name.first_name if @customer.first_name.nil?
        @customer.last_name  = Faker::Name.last_name if @customer.last_name.nil?
      end

      def generate_invitee_email
        invitee_email = "test_invite_friend#{SecureRandom.uuid.delete('-')}"
        @customer.invitee_email = Faker::Internet.email(invitee_email)
      end

      def generate_birth_date
        return unless @customer.birthdate.nil?
        @customer.birthdate = Faker::Date.birthday(min_age: 25, max_age: 40).strftime("%d.%m.%Y")
      end

      # @abstract
      def generate_iban
        raise NotImplementedError.new
      end

      def generate_address
        @customer.house_number = Faker::Address.building_number if @customer.house_number.nil?
        @customer.place =        Faker::Address.city if @customer.place.nil?
        @customer.zip_code =     Faker::Address.zip if @customer.zip_code.nil?
        return unless @customer.address_line1.nil?
        # support compatibility with lib/lifters/domain/addresses/normalizer.rb:25
        @customer.address_line1 = Faker::Address.street_name.strip
                                                .split(" ").map(&:capitalize).join(" ") # titleize
                                                .gsub("strasse", "straße")
                                                .gsub("Strasse", "Straße")
                                                .gsub("str.", "straße")
      end

      def generate_credentials
        @customer.password = "Test1234" if @customer.password.nil?
        @customer.phone_number = ClarkFaker::PhoneNumber.phone_number if @customer.phone_number.nil?
        return unless @customer.email.nil?
        @customer.email = Faker::Internet.email(name: "test_automation_" + SecureRandom.uuid.delete("-"))
      end
    end
  end
end
