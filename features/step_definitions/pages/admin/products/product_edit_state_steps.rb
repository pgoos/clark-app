# frozen_string_literal: true

And(/^admin remembers the number of existing payments$/) do
  @number_of_payments = number_of_payments
end

And(/^admin sees that the number of payments increased$/) do
  expect(number_of_payments).to eq(@number_of_payments + 1)
end

And(/^admin sees that the number of payments is the same$/) do
  expect(number_of_payments).to eq(@number_of_payments)
end

def number_of_payments
  Helpers::OpsUiHelper::TableHelper.new(parent_id: "accounting-transactions").rows_number
end
