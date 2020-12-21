# frozen_string_literal: true

When(/^admin selects "([^"]*)" as the subcompany group$/) do |category|
  page.select category, from: "subcompany_company_id"
end

When(/^admin selects "([^"]*)" as the subcompany vertical$/) do |vertical|
  page.select vertical, from: "subcompany_vertical_ids"
end
