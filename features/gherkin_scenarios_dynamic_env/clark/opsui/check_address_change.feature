@javascript
@desktop_only
Feature: Check address change feature
  As an admin
  I want to be able to see a business event on address change

  @requires_mandate
  Scenario: user changes address from client side
    Given user logs in with the credentials and closes "start demand check" modal

    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page

    # add a new address
    When user enters "Goethestraße" into Straße input field
    And  user enters "10" into Hausnr. input field
    And  user enters "60313" into PLZ input field
    And  user enters "Frankfurt am Main" into Ort input field
    And  user clicks on "Speichern" button
    Then user is on the manager page

    # open OPS UI
    Given admin is logged in ops ui

    # navigate to mandate details page
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # open business events page and verify address metadata
    When admin clicks on "Business-Events verfolgen" link
    Then admin is on the mandate business events page
    And admin sees the update address metadata table with "Frankfurt am Main" in column 4 of row 2
    And admin sees the update address metadata table with "Goethestraße" in column 4 of row 3
    And admin sees the update address metadata table with "60313" in column 4 of row 4
    And admin sees the update address metadata table with "10" in column 4 of row 5

  @requires_mandate
  Scenario: admin changes address from OPS UI
    Given admin is logged in ops ui

    # navigate to mandate details page
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    When admin clicks on "Anschrift hinzufügen" link
    Then admin is on the mandate new address page

    # add a new address
    When admin enters "Goethestraße" into Straße input field
    And  admin enters "10" into Hausnr. input field
    And  admin enters "60313" into PLZ input field
    And  admin enters "Frankfurt am Main" into Ort input field
    And  admin clicks on "Anlegen" button
    Then admin is on the mandate addresses page
    And  admin sees message "Address wurde erfolgreich erstellt."
    And  admin sees table with populated data present on page

    # navigate to mandate details page
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # open business events page and verify address metadata
    When admin clicks on "Business-Events verfolgen" link
    Then admin is on the mandate business events page
    And admin sees the update address metadata table with "Frankfurt am Main" in column 4 of row 2
    And admin sees the update address metadata table with "Goethestraße" in column 4 of row 3
    And admin sees the update address metadata table with "60313" in column 4 of row 4
    And admin sees the update address metadata table with "10" in column 4 of row 5
