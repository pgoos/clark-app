# frozen_string_literal: true

When(/^admin fills out "New opportunity with prospect" form with a customer data$/) do
  @new_opp_with_prospect_page = NewOpportunityWithProspectPage.new
  @new_opp_with_prospect_page.enter_customer_data(@customer)
end

And(/^admin selects "([^"]*)" as an opportunity category$/) do |category|
  @new_opp_with_prospect_page.select_category(category)
end

And(/^admin sees the category "([^"]*)" selected in drop down$/) do |category_name|
  @new_opp_with_prospect_page.assert_category_dropdown(category_name)
end
