# frozen_string_literal: true

module Components
  # This component provides methods for performing operations with input fields
  module Input
    # Method enters provided value into the input field
    # If provided value is nil random will be as a value
    # Custom method can be implemented. Example: def enter_value_into_email_input_field(value) { }
    # @param value [String] value to be send, if nil random string will be entered
    # @param marker [String] custom method marker || input field label || input field name
    def enter_value_into_input_field(value, marker)
      # define value
      value ||= Faker::Lorem.characters(number: Random.new.rand(4...12).to_i)
      # dispatch
      custom_method = "enter_value_into_#{marker.tr(' ', '_')}_input_field"
      if respond_to?(custom_method, true)
        send(custom_method, value)
        sleep 0.5
        return
      end

      # default generic implementation
      # TODO: please, do something with this!
      begin
        find("label", text: marker, wait: 1).find(:xpath, "..", wait: 1).find("input", wait: 1).set(value)
        sleep 0.5
      rescue Capybara::ElementNotFound
        fill_in marker, with: value
      end
    end

    # Method enters some customer data to the provided input field
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def enter_customer_data_email(customer) { }
    # @param customer [Model::Customer] instance of Customer struct
    # @param marker [String] custom method marker
    def enter_customer_data(customer, marker)
      send("enter_customer_data_#{marker.tr(' ', '_')}", customer)
      sleep 1 # ensure that input was handled
    end

    # Method asserts that page contains target input field
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_search_input_field() { }
    # @param marker [String] custom method marker
    def assert_input_field(marker)
      send("assert_#{marker.tr(' ', '_')}_input_field")
    end

    # Method asserts the text in input field
    # DISPATCHER METHOD
    # Custom method MUST be implemented. Example: def assert_text_in_search_input_field() { }
    # @param value [String] value to be send
    # @param marker [String] custom method marker
    def assert_text_in_input_field(value, marker)
      send("assert_text_in_#{marker.tr(' ', '_')}_input_field", value)
    end
    # cross-page shared methods ----------------------------------------------------------------------------------------

    def enter_customer_data_verification_token(customer)
      sleep 1
      token = TestContextManager.instance.sms_service.get_verification_token(customer.phone_number)
      find(".cucumber-verification-code-input").set(token)
    end
  end
end
