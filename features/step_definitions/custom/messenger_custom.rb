# frozen_string_literal: true

# Contains Messenger related composite custom steps
# TODO: split this composite steps into smaller re-usable and parameterized steps

When(/^admin receives "([^"]*)" message in OPS UI$/) do |message|
  # TODO: probably, we should split this step into 2-3 small steps
  Helpers::TabSwitcher.switch_to_next_tab
  step "admin is logged in ops ui"
  step 'admin clicks on "Kunden" link'
  step "admin is on the mandates page"
  step "admin clicks on the test mandate id in a table"
  step "admin is on the mandate details page"
  step 'admin clicks on "Interaktionen" section eye button'
  step "admin can see that the latest message is \"#{message}\""
end

When(/^user receives "([^"]*)" message from admin site$/) do |message|
  # TODO: probably, we should split this step into 2-3 small steps
  Helpers::TabSwitcher.switch_to_next_tab

  # Ember messenger is disabled for IE
  step 'admin clicks on "Nachricht" link'
  step "admin enters message \"#{message}\""

  if TestContextManager.instance.ie_browser?
    step 'admin clicks on "Erstellen" button'
    step "admin is on the mandate details page"
    step 'admin clicks on "Interaktionen" section eye button'
  else
    step 'admin clicks on "Nachricht senden" button'
  end

  step "admin can see that the latest message is \"#{message}\""
  step "admin sees that \"#{message}\" is marked as admin message"
  step "admin sees that input field for messages is empty"
  step 'admin sees that "Nachricht senden" button is disabled'

  Helpers::TabSwitcher.switch_to_first_tab
  step "user is on the manager page"
end
