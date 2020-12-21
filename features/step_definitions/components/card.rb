# frozen_string_literal: true

# When -----------------------------------------------------------------------------------------------------------------

When(/^user clicks on ([^"]*) card(?:\s?"([^"]*)")?$/) do |marker, card|
  patiently do
    card_page_context.click_on_card(marker, card.presence)
  end
end

When(/^(?:user|admin) clicks (\D+) property on (\D+) card (?:\s?"([^"]*)")?$/) do |card_property, marker, card_title|
  card_page_context.click_property_on_card(card_property, marker, card_title)
end

# Then -----------------------------------------------------------------------------------------------------------------

Then(/^user sees (\D+) card(?:\s?"([^"]*)")?$/) do |marker, card|
  patiently do
    card_page_context.assert_card(marker, card.presence, nil)
  end
end

Then(/^user sees (\D+) cards$/) do |marker, table|
  patiently do
    card_page_context.assert_card(marker, nil, table)
  end
end

Then(/^user sees (\d+) ([^"]*) cards?$/) do |amount, marker|
  card_page_context.assert_amount_of_cards(marker, amount)
end

Then(/^user doesn't see ([^"]*) cards?(?:\s?"([^"]*)")?$/) do |marker, card|
  patiently do
    card_page_context.assert_no_card(marker, card.presence)
  end
end

Then(/^user sees that ([^"]*) for "([^"]*)" card is "([^"]*)"$/) do |marker, card, text|
  card_page_context.assert_property_of_card(marker, card, text)
end

Then(/^user sees that ([^"]*) card "([^"]*)" is not clickable$/) do |marker, card|
  card_page_context.assert_card_is_not_clickable(marker, card)
end

# Context --------------------------------------------------------------------------------------------------------------

private

# @return [Components::Card]
def card_page_context
  PageContextManager.assert_context(Components::Card)
  PageContextManager.context
end
