@smoke
@javascript
@enable_tracking_scripts
@desktop_only
Feature: Mandate Registers as payback user
  As a payback user
  I want to to add my payback kunden number to register with clark
  After I add payback number I can get payback points from clark


  Scenario: Payback user enters Kunden Number in mandate funnel
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | zip_code | phone_number | source  |
      | Payback    | Automation | Test1234 | 01.01.1990 | Goethestraße,10 | 10           | 60313    | 15166318279  | payback |

    When user navigates to payback page
    And  user clicks on "Jetzt starten" link
    Then user is on the Payback form page
    And  user sees payback input field

    When user clicks payback icon
    And  user sees text "Kundennummer auf der PAYBACK Karte"
    Then user clicks on "OK" button

    # invalid number format
    When user enters "123455" into payback input field
    Then user clicks on "Weiter" button
    And  user sees text "Die eingegebene PAYBACK Kundennummer ist nicht korrekt."

    # Step 1
    When user enters their payback code data
    And  user clicks on "Weiter" button
    Then user is on the mandate funnel status page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    When user clicks on "Weiter" button
    Then user is on the phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees categories list
    And  user sees search input field

    When user enters "gesetz" into search input field
    And  user selects "Gesetzliche Krankenversicherung" targeting option
    Then user is on the company selection page
    And  user is on the "Gesetzliche Krankenversicherung" category company targeting path

    When user enters "AOK" into search input field
    Then user sees the company search results

    When user selects "AOK Baden-Württemberg" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Gesetzliche Krankenversicherung" category and "AOK Baden-Württemberg" company

    When user sees categories list
    And  user sees search input field

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
    Then user is on the confirming page
    And  user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    And  user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    Then user waits until "signature" modal is closed
    And  user clicks on "Bestätigen" button
    And  user is on the mandate register page

    # Step 5
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Step 6
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees contract card "Gesetzliche Krankenversicherung - AOK Baden-Württemberg"

    # Check the points reserved for payback user
    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page
    And  user sees text "Reservierte Punkte"
    And  user sees text "Freigegebene Punkte"
    And  user sees text "Kundennummer"
    And  user sees text "Wenn du Hilfe bei der Verwaltung deiner PAYBACK-Kundenummer benötigst, kontaktiere uns bitte."
    And  user sees text "Zusammenfassung der Punkte"

    # TODO: log out
    When user clicks on "Verträge" link
    Then user is on the manager page

    When user opens profile menu
    And  user clicks on "Ausloggen" link
    Then user is on the home page

    # try to register for the second time with the same payback code
    When user navigates to payback page
    And  user clicks on "Jetzt starten" link
    Then user is on the Payback form page
    And  user sees payback input field

    When user enters their payback code data
    And  user clicks on "Weiter" button
    And  user sees text "Diese PAYBACK Kundenummer ist bereits bei uns registriert."


  Scenario: Payback user adds Kunden Number after mandate funnel
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | zip_code | phone_number | source  |
      | Payback    | Automation | Test1234 | 01.01.1990 | Goethestraße,10 | 10           | 60313    | 15166318279  | payback |

    When user navigates to payback page
    And  user clicks on "Jetzt starten" link
    Then user is on the Payback form page
    And  user sees payback input field

    When user clicks payback icon
    And  user sees text "Kundennummer auf der PAYBACK Karte"
    Then user clicks on "OK" button

    # Step 1
    When user clicks on "Später" button
    Then user is on the mandate funnel status page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    When user clicks on "Weiter" button
    Then user is on the phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees categories list
    And  user sees search input field

    When user enters "Unfall" into search input field
    And  user selects "Unfallversicherung" targeting option
    Then user is on the company selection page
    And  user is on the "Unfallversicherung" category company targeting path

    When user enters "Allianz Versicherung" into search input field
    Then user sees the company search results

    When user selects "Allianz Versicherung" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Unfallversicherung" category and "Allianz Versicherung" company

    When user sees categories list
    And  user sees search input field

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
    Then user is on the confirming page
    And  user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    And  user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    Then user waits until "signature" modal is closed
    And  user clicks on "Bestätigen" button
    Then user is on the mandate register page

    # Step 5
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Step 6
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees contract card "Unfallversicherung - Allianz Versicherung"

    # Check the points reserved for payback user
    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page
    And  user sees text "Kein PAYBACK Konto verbunden"

    When user clicks on "Konto verbinden" link
    Then user is on the Payback form page
    And  user sees payback input field

    # TODO: update this line
    When user enters their payback code data
    And  user clicks on "Weiter" button
    Then user is on the manager page

    When user opens profile menu
    And  user clicks on "Persönliche Angaben" link
    Then user is on the profiling page
    And  user sees text "PAYBACK Konto"

    # Accept user and verify details in admin ui
    Given admin is logged in ops ui

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the Payback mandate in a table
    Then admin is on the mandate details page
    And  admin sees text "payback"

    # Accept customer to add points
    When admin clicks on "Akzeptieren" link
    Then admin sees text "Die Informationen für diesen Kunde wurden akzeptiert."

    When admin refreshes the page
    Then admin sees locked points "500"

    # Check points refund on cancellation of inquiry by admin
    When admin clicks the inquiry
    And  admin is on the inquiry details page
    And  admin clicks on "Abbrechen" link
    And  admin cancells the inquiry with a "contract_not_found" reason
    And  admin clicks on "Fortsetzen" button
    And  admin is on the inquiry details page
    Then admin sees text "Abbruch von Anfragekategorien erfolgreich."

    # verify refunded points
    When admin clicks on "Payback Automation" link
    Then admin is on the mandate details page
    # TODO: Put it back to 250 after 31.01.2021
    And  admin sees locked points "0"
