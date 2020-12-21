@javascript
@desktop_only
Feature: Get payment gap csv
  As a admin
  I want to be able to create payment gap csv

  Scenario: Schedule payment gap csv generation no change to date

    # login to ops ui and navigate to upload accounting reports page
    Given admin is logged in ops ui

    When admin clicks on "Upload Abrechnung" link
    Then admin is on the payment gap download page
    And admin sees message "csv Datei herunterladen"
    And admin sees "accounting_report_from" input field
    And admin sees "accounting_report_to" input field

    # scheduling payment gap csv generation
    When admin clicks on "per E-mail an mich senden" button
    Then admin is on the payment gap download page
    And admin sees message "Der Export wird verarbeitet und in Kürze an deine E-Mail-Adresse geschickt."

  Scenario: Schedule payment gap csv generation to a certain cut-off date

    # login to ops ui and navigate to upload accounting reports page
    Given admin is logged in ops ui
    When admin clicks on "Upload Abrechnung" link
    Then admin is on the payment gap download page
    And admin sees message "csv Datei herunterladen"

    # scheduling payment gap csv generation with given dates
    # passing dates as 12.23.2019 is adding an extra charcter in the year section
    # hence use dates in 09.05.2019 format because datepicker only accepts this
    When admin enters "09.05.2019" into accounting_report_from input field
    And admin enters "09.05.2019" into accounting_report_to input field
    And admin clicks on "per E-mail an mich senden" button
    Then admin is on the payment gap download page
    And admin sees message "Der Export wird verarbeitet und in Kürze an deine E-Mail-Adresse geschickt."
