@javascript
@desktop_only
Feature: Invite new user by email in OPS UI
  As an admin
  I want to invite new users by sending them the email

  Scenario Outline: Invite user via email
    Given admin is logged in ops ui
    And user is as the following
    | first_name | last_name      |
    | Test       | Automation     |

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on "Kunde einladen" link
    Then admin is on the new mandate form page

    When admin fills "Vorname" with customer first_name
    And admin fills "Nachname" with customer last_name
    And admin fills "Geburtsdatum (TT.MM.JJJJ)" with customer birthdate
    And admin fills "Straße" with customer address_line1
    And admin fills "Hausnr." with customer house_number
    And admin fills "PLZ" with customer zip_code
    And admin fills "Ort" with customer place
    And admin enters the mandate email address
    And admin fills "Telefon" with customer phone_number
    And admin selects the owner as "<owner_name>"
    And admin clicks on "Anlegen" button
    Then admin is on the mandates page
    And admin sees message "Kunde-Account wurde erfolgreich erstellt."

    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    When admin clicks on the "Kunde einladen" link and accept confirmation popup
    Then admin sees message "E-Mail verschickt"

    Examples:
    |owner_name   |
    |zvo          |
    #TODO: Add more owners when OPS ui will be faster
    #TODO: is it a copy paste of "Create a new mandate in opsui" test?
