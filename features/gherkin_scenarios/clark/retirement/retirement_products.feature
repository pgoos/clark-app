@javascript
@enable_tracking_scripts
Feature: Retirement Products
  As a Clark client
  I want to be able to manage my retirement products

  @stagings_only
  @requires_mandate
  Scenario: Customer creates a retirement product and uploads a document
    Given user logs in with the credentials and closes "start demand check" modal
    And   user completes the pension check with the answers
      | Was machst du beruflich? | Wie hoch ist dein aktuelles Jahresbruttogehalt? |
      | Angestellter             | 60000                                           |
    Then  user is on the retirement cockpit page

    # Open new product page
    When user clicks on "produkte hinzufugen" button
    Then user is on the input details page

    # Fill new product form
    When user selects "Betriebliche Altersvorsorge" option in Rentenart dropdown
    And  user selects "Pensionsfonds" option in Renten-Kategorie dropdown
    And  user enters "Allianz" into Name des Versicherers input field
    And  user selects "Allianz Pensionsfonds Aktiengesellschaft" option in dropdown
    And  user selects "14.02.2025" date in Renteneintrittsdatum calendar
    And  user enters "500" into Monatliches Renteneinkommen inkl. Fondwachstum (3%) input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Pensionsfonds"

    # Open created product details
    When user clicks on retirement product card "Pensionsfonds"
    Then user is on the product details page

    # Upload the document and check results
    When user scrolls to upload documents section
    And  user uploads product document
    Then user sees 1 uploaded document card
