# frozen_string_literal: true

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees that ([^"]*) checkout step is active$/) do |step|
  checkout_step_context.assert_step_is_active(step)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::CheckoutStepper]
def checkout_step_context
  PageContextManager.assert_context(Components::CheckoutStepper)
  PageContextManager.context
end
