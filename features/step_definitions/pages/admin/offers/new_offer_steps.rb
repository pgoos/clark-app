# frozen_string_literal: true

When(/^admin fills out new offer form with the following values$/) do |table|
  @new_offer_page = NewOfferPage.new
  offer_options = table.hashes
  offer_options.each do |option|
    option_number = option.delete("offer option number")
    option.each { |k, v| @new_offer_page.set_value(option_number, k, v) }
  end
end

And(/^admin marks (\d) offer option as a recommended$/) do |offer_option_number|
  @new_offer_page.mark_recommended(offer_option_number)
end

And(/^admin adds following coverages to the offer comparison view$/) do |table|
  table.raw.each { |param| @new_offer_page.add_param_to_offer_view(param.first) }
end

And(/^admin enters "([^"]*)" message for a customer$/) do |message|
  @new_offer_page.enter_message_for_customer(message)
end
