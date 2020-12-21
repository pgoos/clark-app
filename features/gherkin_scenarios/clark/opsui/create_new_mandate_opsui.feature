@javascript
@desktop_only
Feature: Create a new mandate in opsui
  As a admin
  I want to be able to create a new mandate in opsui

  @stagings_only
  Scenario: Create a new mandate in opsui
    Given user is as the following
      | first_name | last_name      |
      | Clark      | Mandate Tester |

    # login to ops ui
    And admin is logged in ops ui

    # navigate to mandates page
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # open new mandate form
    When admin clicks on "Kunde einladen" link
    Then admin is on the new mandate form page

    # fill the form
    When admin fills "Vorname" with customer first_name
    And admin fills "Nachname" with customer last_name
    And admin fills "Geburtsdatum (TT.MM.JJJJ)" with customer birthdate
    And admin fills "Straße" with customer address_line1
    And admin fills "Hausnr." with customer house_number
    And admin fills "PLZ" with customer zip_code
    And admin fills "Ort" with customer place
    And admin enters the mandate email address
    And admin fills "Telefon" with customer phone_number
    And admin selects the owner as "malburg"
    And admin enters the reference number as "malburgTestAccount"
    And admin clicks on "Anlegen" button

    # check result
    Then admin sees message "Kunde-Account wurde erfolgreich erstellt."
    And admin is on the mandates page
    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page
    And admin sees mandate status as "in Erstellung"

    # navigate to action items page
    When admin clicks on "Aufgaben" link
    Then admin is on the work items page

    # navigate to changed address action items and check new mandate
    When admin clicks on "geänderte Adressen" link
    Then admin does not see current user in the changed adresses table
