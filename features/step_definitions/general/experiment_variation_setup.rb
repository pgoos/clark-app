# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^the local storage item ([^"]*) has the following values$/) do |item, table|
  Helpers::ExperimentVariationHelper.set_experiments(item, table.rows_hash)
end

