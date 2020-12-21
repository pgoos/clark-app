# frozen_string_literal: true

# Contains steps definitions for basic data setup (mandates, products, etc)

# Customers & Mandates -------------------------------------------------------------------------------------------------

Given(/^(?:user) is as the following$/) do |table|
  @customer = TestContextManager.instance
                                .mandate_helper
                                .generate_mandate(Helpers::TableStepHelper.build_single(table, Model::Customer))
end

# TODO: split into 2 separate steps - "user is", and "user has a contract" (add a table for the contract details)
# TODO: convert to a table step. Add an ability to provide customer personal data
Given(/^user is a (self service|mandate) customer with a contract$/) do |customer_state|
  api_facade = ApiFacade.new
  customer_details = api_facade.automation_helpers.post_create_new_customer(customer_state)
  @customer.email = customer_details["customer"]["email"]
  contract_details = api_facade.automation_helpers.post_create_new_contract(@customer.email)
  @new_product_number = contract_details["contract"]["id"].to_s
end

Given(/^user completes the mandate funnel with(?: an)? inquir(?:y|ies)$/) do |table|
  TestContextManager.instance.mandate_helper.register_mandate(@customer, table.rows)
end

When(/^user decides to use "([^"]*)" as a new "([^"]*)"$/) do |value, attribute|
  TestContextManager.instance.mandate_helper.update_customer_attribute(@customer, value, attribute)
end

# Products -------------------------------------------------------------------------------------------------------------

Given(/user has the following product$/) do |table|
  @new_product_number = Helpers::ProductHelper.create_new_product(@customer, table.hashes)
end

# Offers --------------------------------------------------------------------------------------------------------------

Given(/^user has its single option offer created for ([^"]*) category/) do |category_name|
  offer = Helpers::OfferHelper::create_new_offer(@customer,
                                                 category_name)
end

# Offers --------------------------------------------------------------------------------------------------------------

Given(/^user has its single option offer created for ([^"]*) category/) do

end

# Questionnaires -------------------------------------------------------------------------------------------------------

# TODO: add to API facade ability to complete demand check and update this code
# TODO: add parametrization
# TODO: see if there is a way to implement the solution without using %{} for better step readability
Given(/^user completes the demand check$/) do
  steps %Q{
    # Demand Check Section
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DemandcheckIntro           | control          |
    And  user clicks on "Bedarf" link
    And  user clicks on "Bedarfscheck starten" button
    Then user is on the demand check page
    And  user sees "Wo wohnst du?" question label

    # Question 1
    When user selects "In einer gemieteten Wohnung" questionnaire option

    # Question 2
    Then user sees "Planst du innerhalb der nächsten 12 Monate eine Immobilie zu (re-)finanzieren?" question label
    When user selects "Ja, ich plane eine Anschlussfinanzierung" questionnaire option

    # Question 3
    Then user sees "Besitzt du eines der folgenden Fahrzeuge?" question label
    When user selects questionnaire options
    | option   |
    | Auto     |
    | Motorrad |

    And user clicks on "Weiter" button

    # Question 4
    Then user sees "Wie ist deine Familiensituation?" question label
    When user selects "Ich bin Single" questionnaire option

    # Question 5
    Then user sees "Hast du Kinder?" question label
    When user selects "Nein" questionnaire option

    # Question 6
    Then user sees "Was machst du beruflich?" question label
    When user selects "Angestellter" questionnaire option
    And user clicks on "Weiter" button

    # Question 7
    Then user sees "Was machst du in deiner Freizeit?" question label
    When user selects questionnaire options
    | option                               |
    | Ich reise sehr viel                  |
    | Ich arbeite gerne in Haus und Garten |
    And user clicks on "Weiter" button

    # Question 8
    Then user sees "Hast du Tiere?" question label
    When user selects questionnaire options
    | option |
    | Hund   |
    | Katze  |

    And user clicks on "Weiter" button

    # Question 9
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label
    When user enters "60000" into answer input field
    And user clicks on "Speichern" button
    Then user is on the recommendations page
  }
end

# TODO: add to API facade ability to complete demand check and update this code
# TODO: add parametrization
When(/^user completes the pension check with the answers$/) do |table|
  steps %Q{
    When user clicks on "rentencheck" button
    Then user is on the Rentencheck intro page

    When user clicks on "Rentencheck starten" button
    Then user is on the rentencheck questionnaire page
    Then user sees "Was machst du beruflich?" question label

    When user selects "#{table.hashes[0]['Was machst du beruflich?']}" questionnaire option
    And user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

    When user enters "#{table.hashes[0]['Wie hoch ist dein aktuelles Jahresbruttogehalt?']}" into answer input field
    And  user clicks on "Speichern" button
    Then user sees text "Analysiere Daten…"
  }
end
