@javascript
@desktop_only
Feature: Delete mandate in opsui
  As a admin
  I want to be able to delete the mandate in opsui

  @requires_mandate
  Scenario: Delete the mandate in opsui
    Given admin is logged in ops ui

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    And admin sees the inquiry

    When admin clicks the inquiry
    Then admin is on the inquiry details page

    When admin clicks on the "löschen" link and accept confirmation popup
    Then admin is on the inquiries page

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    When admin clicks on the "löschen" link and accept confirmation popup
    Then admin sees message "Kunde erfolgreich gelöscht."
