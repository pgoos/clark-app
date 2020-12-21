# frozen_string_literal: true

# Contains steps definitions for freyr

When(/clark updates owner to "([^"]*)"/) do |owner_ident|
  ApiFacade.new.automation_helpers.post_update_owner_ident(owner_ident, @customer)
end
