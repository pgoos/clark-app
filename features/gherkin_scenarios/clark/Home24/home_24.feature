@smoke
@javascript
@enable_tracking_scripts
@desktop_only
Feature: Mandate Registers as home24 user and adds order number
  As a home24 user
  I want to to add my order number to register with clark
  After I add my order number and add two insurances I can get a free furniture insurance from clark


  Scenario: Home24 user enters Order Number in mandate funnel
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | zip_code | phone_number | source  |
      | Home24     | Automation | Test1234 | 01.01.1991 | Wilhelleuchstr  | 10           | 60313    | 15166318279  | home24  |

    When user navigates to home24 page
    And  the local storage item clark-experiments has the following values
      | 2020Q4DemandcheckPrimer | control |
    Then user is on the home24 page

    When  user clicks on "Jetzt Möbel absichern" link
    Then user is on the mandate funnel status home twenty four page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    When user sees text "Bitte gib deine Bestellnummer ein, um dir deine gratis CLARK Möbelversicherung zu sichern"
    And  user sees text "Teilnahmebedingungen"
    And  user sees order number input field
    And  user enters their home24 code data

    When user clicks on "Weiter" button
    Then user is on the phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    Then user is on the phone verification page

    When  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees categories list
    And  user sees search input field

    When user enters "Hausrat" into search input field
    And  user selects "Hausrat" targeting option
    Then user is on the company selection page
    And  user is on the "Hausrat" category company targeting path

    When user enters "ADAC" into search input field
    Then user sees the company search results

    When user selects "ADAC" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Hausrat" category and "ADAC" company

    When user sees categories list
    Then user sees search input field

    When user enters "privathaft" into search input field
    And  user selects "Privathaftpflicht" targeting option
    Then user is on the company selection page
    And  user is on the "Privathaftpflicht" category company targeting path

    When user enters "ACE" into search input field
    Then user sees the company search results

    When user selects "ACE" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Privathaftpflicht" category and "ACE" company

    When user clicks on "Weiter" button
    Then user is on the profiling page

    # Step 3
    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the confirming home twenty four page
    And  user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    And user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    Then user waits until "signature" modal is closed

    When user selects home24 terms condition checkbox
    And  user selects home24 signature rules checkbox
    And  user sees that "Bestätigen" button is visible
    And  user clicks on "Bestätigen" button
    Then user is on the mandate register page

    # Step 5
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Step 6
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees contract card "Hausrat - ADAC"
    And  user sees contract card "Privathaftpflicht - ACE"

    # Accept user and verify details in admin ui
    Given admin is logged in ops ui

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the Home24 mandate in a table
    Then admin is on the mandate details page
    And  admin sees text "home24"

    # Accept customer to add points
    When admin clicks on "Akzeptieren" link
    Then admin sees text "Die Informationen für diesen Kunde wurden akzeptiert."
