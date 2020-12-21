# frozen_string_literal: true

module Components
  # Component that provides method to operate with checkout stepper
  module CheckoutStepper
    # Assertions -------------------------------------------------------------------------------------------------------
    def assert_step_is_active(step_name)
      expect(find("span", text: step_name.to_s).find(:xpath, "..")["aria-current"]).to eq("page")
    end
  end
end
