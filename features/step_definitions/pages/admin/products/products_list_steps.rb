# frozen_string_literal: true

And(/^admin clicks on the first product in the table$/) do
  ProductsPage.new.click_on_first_product
end
