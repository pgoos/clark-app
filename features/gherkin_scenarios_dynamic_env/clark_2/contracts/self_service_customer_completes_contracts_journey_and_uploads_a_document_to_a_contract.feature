@javascript
Feature: Self-service customer completes contract journey and uploads a document to a contract
  As a self-service customer
  I want to complete contracts journey in Clark 2 and upload a document to my contract

  @smoke
  Scenario: Self-service customer completes contract journey and uploads a document to a contract
    Given user is as the following
      | first_name |
      | Clark 2.0  |

    # Start customer journey
    When user navigates to clark 2 starting page
    Then user is on the clark 2 contract adding exploration page

    When user clicks on "Jetzt starten" link
    Then user is on the clark 2 select category page

    # Select contract category
    When user clicks on popular option card "Privathaftpflicht"
    Then user is on the clark 2 select company page

    # Select contract company
    When user clicks on popular option card "Allianz Versicherung"
    Then user is on the clark 2 select category page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    # Complete self-service customer registration
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

    # Navigate the contract details page and check content of the page
    When user clicks on contract card "Privathaftpflicht"
    Then user is on the clark 2 contract details page
    And  user sees text "Bitte Vertrag hochladen"
    And  user sees "Privathaftpflicht" contract details title label
    And  user sees "Allianz Versicherung" contract details secondary title label
    And  user sees "3 items" tips and info section

    # Upload documents and check results
    When user uploads contract document
    Then user sees "Geschafft!" modal

    When user closes "Geschafft!" modal
    And  user uploads contract document
    Then user sees "Geschafft!" modal

    When user closes "Geschafft!" modal
    Then user sees waiting period label
    And  user sees 2 document cards
    But  user doesn't see text "Bitte Vertrag hochladen"

    # Navigate to Manager page
    When user clicks on "Verträge" link
    Then user is on the manager page
