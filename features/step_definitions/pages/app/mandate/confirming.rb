# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user enters their signature$/) do
  patiently do
    confirming_page_context.draw_signature
  end
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [AppPages::Confirming]
def confirming_page_context
  PageContextManager.assert_context(AppPages::AbstractConfirming)
  PageContextManager.context
end
