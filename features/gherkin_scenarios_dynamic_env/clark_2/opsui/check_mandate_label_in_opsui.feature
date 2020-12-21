@javascript
@desktop_only
@smoke
Feature: Check mandate label in opsui
  As an admin
  I want to be able to see clark 2.0 label with clark2 customers

  Scenario: check clark2 label appears with clark2 customers
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    When user navigates to clark 2 starting page
    Then user is on the clark 2 contract adding exploration page

    When user clicks on "Jetzt starten" link
    Then user is on the clark 2 select category page

    When user clicks on popular option card "Privathaftpflicht"
    Then user is on the clark 2 select company page

    When user clicks on popular option card "Allianz Versicherung"
    Then user is on the clark 2 select category page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    When user clicks on "Auswahl bestätigen" button
    Then user is on the clark 2 registration page
    And  user sees text "Sichere deinen Fortschritt"
    And  user sees email address input field
    And  user sees password input field

    When user enters their email address data
    And  user enters their password data
    And  user clicks on "Jetzt registrieren" button
    Then user is on the clark 2 rewards page
    And  user sees text "Geschafft!"

    When user clicks on "Zu deinen Verträgen" link
    Then user is on the manager page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    # Verify the Clark2 labels in OPS UI for new customer

    When admin is logged in ops ui
    And  admin clicks on "Kunden" link
    Then admin is on the mandates page
    And  admin sees "Clark 2.0" label with the test mandate id in the table

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    And  admin sees "Clark 2.0" label with the mandate

    When admin clicks on the first product in the table
    Then admin is on the product_details page
    And  admin sees "Clark 2.0" label with the mandate
