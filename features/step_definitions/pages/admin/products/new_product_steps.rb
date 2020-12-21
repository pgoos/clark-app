# frozen_string_literal: true

When(/^admin selects "([^"]*)" as the product category$/) do |category|
  @new_product ||= NewProductPage.new
  @new_product.select_product_category(category)
end

When(/^admin selects "([^"]*)" as the product group$/) do |group|
  @new_product.select_product_group(group)
end

When(/^admin selects "([^"]*)" as the product sub company$/) do |sub_company|
  @new_product.select_product_sub_company(sub_company)
end

When(/^admin selects "([^"]*)" as the product tarif$/) do |tarif|
  @new_product.select_product_tarif(tarif)
end

When(/^admin fills product number with random value$/) do
  @new_product_number = @new_product.enter_random_product_number
end

When(/^admin selects "([^"]*)" as the product premium period$/) do |period|
  @new_product.select_product_premium_period(period)
end
