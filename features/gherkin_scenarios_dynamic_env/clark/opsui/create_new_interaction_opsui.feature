@javascript
@desktop_only
Feature: Create a new interaction in opsui
  As an admin
  I want to be able to create a new interaction in opsui

  @stagings_only
  @requires_mandate
  Scenario: Create a new interaction for product in opsui
    Given user has the following product
    | category_name     | company_name |
    | Privathaftpflicht | ADAC         |
    And admin is logged in ops ui

    When admin clicks on "Produkte" link
    And admin clicks on the test product id in a table
    Then admin is on the product_details page
    And admin sees "0 Interaktionen" page section

    When admin clicks on "Interaktionen" section eye button
    And admin clicks on "E-Mail" link
    Then admin sees text "Neue E-Mail anlegen"

    When admin enters "Test Email" into Betreff input field
    And admin enters "This is a Test Email" into Inhalt input field
    And admin clicks on "Erstellen" button
    Then admin sees "1 Interaktionen" page section
    And admin sees text "Test Email"
    And admin sees text "This is a Test Email"
