# frozen_string_literal: true

Then("admin sees the states in dropdown list") do |table|
  expect(page).to have_select(:state, with_options: table.raw.flatten)
end

Then("admin doesn't see the states in dropdown list") do |table|
  expect(page).not_to have_select(:state, with_options: table.raw.flatten)
end
