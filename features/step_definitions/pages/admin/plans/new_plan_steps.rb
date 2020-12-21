# frozen_string_literal: true

When(/^admin selects "([^"]*)" as the plan category$/) do |category|
  Helpers::OpsUiHelper.select_combobox_option("plan_category_id", category)
end

When(/^admin selects "([^"]*)" as the plan group$/) do |group|
  page.select group, from: "plan_company_id"
end

And(/^admin selects "([^"]*)" as the plan premium period$/) do |period|
  page.select period, from: "plan_premium_period"
end

Then("admin sees a message of success") do
  successful_message = I18n.t("flash.actions.create.notice", resource_name: Plan.model_name.human)
  expect(page).to have_text(successful_message)
end
