@enable_tracking_scripts
@javascript
@smoke
Feature: Mandate Registration Flow
  As an organic, miles and more or 1822 direkt
  I want to be able to register and see my cockpit
  After I finish the steps I will become a user

  @cms
  Scenario: Mandate registers sees the cockpit
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | place     | zip_code | phone_number |
      | Clark      | Automation | Test1234 | 01.01.1970 | Goethestraße,10 | 10           | Frankfurt | 60313    | 15166318279  |

    When user navigates to first page of mandate funnel
    And  the local storage item clark-experiments has the following values
      | 2020Q4DemandcheckPrimer | control |
    Then user sees app page header is visible [desktop view only]
    And  user sees that "Verträge" link is not visible
    And  user sees that "Bedarf" link is not visible
    And  user sees that "Freunde einladen" link is not visible
    And  user sees that "Rente" link is not visible
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    # Step 1
    When user clicks on "Weiter" button
    Then user is on the phone verification page
    And  user sees "1 of 5" step number label
    And  user sees 4 trust icons

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user is on the phone verification page
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees "2 of 5" step number label
    And  user sees categories list
    And  user sees search input field

    When user enters "priva" into search input field
    And  user selects "Privathaftpflicht" targeting option
    Then user is on the company selection page
    And  user is on the "Privathaftpflicht" category company targeting path
    And  user sees search input field

    When user enters "allianz" into search input field
    Then user sees the company search results

    When user selects "Allianz Versicherung" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Privathaftpflicht" category and "Allianz Versicherung" company

    When user clicks on "Weiter" button
    Then user is on the profiling page
    And  user sees "3 of 5" step number label
    And  user sees that "mandate document" link is not visible

    # Step 3
    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the confirming page
    And  user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    Then user sees "4 of 5" step number label
    And  user sees that "Bestätigen" button is disabled

    When user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    And  user waits until "signature" modal is closed
    Then user sees that "Bestätigen" button is visible

    When user clicks on "Bestätigen" button
    Then user is on the mandate register page
    And  user sees "5 of 5" step number label

    # Step 5
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Finalize
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees that "Verträge" link is visible
    And  user sees that "Bedarf" link is visible
    And  user sees that "Rente" link is visible
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    When user opens profile menu
    Then user sees that "Freunde einladen" link is visible

    # Demand Check Section
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DemandcheckIntro           | control          |
    And  user clicks on "Bedarf" link
    And  user clicks on "Bedarfscheck starten" button
    Then user is on the demand check page
    And  user sees "Wo wohnst du?" question label

    # Question 1
    When user selects "In einer gemieteten Wohnung" questionnaire option
    Then user sees "Planst du innerhalb der nächsten 12 Monate eine Immobilie zu (re-)finanzieren?" question label

    # Question 2
    When user selects "Ja, ich plane eine Anschlussfinanzierung" questionnaire option
    Then user sees "Besitzt du eines der folgenden Fahrzeuge?" question label

    # Question 3
    When user selects questionnaire options
      | option   |
      | Auto     |
      | Motorrad |
    And  user clicks on "Weiter" button
    Then user sees "Wie ist deine Familiensituation?" question label

    # Question 4
    When user selects "Ich bin Single" questionnaire option
    Then user sees "Hast du Kinder?" question label

    # Question 5
    When user selects "Nein" questionnaire option
    Then user sees "Was machst du beruflich?" question label

    # Question 6
    When user selects "Angestellter" questionnaire option
    And  user clicks on "Weiter" button
    Then user sees "Was machst du in deiner Freizeit?" question label

    # Question 7
    When user selects questionnaire options
      | option                               |
      | Ich reise sehr viel                  |
      | Ich arbeite gerne in Haus und Garten |
    And  user clicks on "Weiter" button
    Then user sees "Hast du Tiere?" question label

    # Question 8
    When user selects questionnaire options
      | option |
      | Hund   |
      | Katze  |
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

    # Question 9
    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the recommendations page

    When user closes "first recommendation" modal
    And  user opens profile menu
    And  user clicks on "Ausloggen" link
    Then user is on the home page

    # Skip below steps in mobile browser
    Given skip below steps in mobile browser

    Given admin is logged in ops ui

    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    When admin clicks on the Clark mandate in a table
    Then admin is on the mandate details page

    # Accept customer to add points
    When admin clicks on "Akzeptieren" link
    Then admin sees text "Die Informationen für diesen Kunde wurden akzeptiert."
    And  "user" receives an email with the content "willkommen bei Clark"

  @stagings_only
  @cms
  Scenario: 1822direkt Mandate registers sees the cockpit
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | place     | zip_code | phone_number |
      | Clark      | Automation | Test1234 | 01.01.1970 | Goethestraße,10 | 10           | Frankfurt | 60313    | 1724568899   |

    When user navigates to one thousand eight hundred twenty twodirekt page
    And  the local storage item clark-experiments has the following values
      | 2020Q4DemandcheckPrimer | control |
    And  user clicks on "Jetzt starten" link
    Then user is on the mandate funnel status page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    # Step 1
    When user clicks on "Weiter" button
    Then user is on the phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user is on the phone verification page
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufüg" button
    Then user is on the targeting selection page
    And  user sees categories list
    And  user sees search input field

    When user enters "privathaftpflicht" into search input field
    And  user selects "Privathaftpflicht" targeting option
    Then user is on the company selection page
    And  user is on the "Privathaftpflicht" category company targeting path

    When user enters "allianz" into search input field
    Then user sees the company search results

    When user selects "Allianz Versicherung" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Privathaftpflicht" category and "Allianz Versicherung" company

    When user clicks on "Weiter" button
    Then user is on the profiling page

    # Step 3
    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the confirming page
    Then user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    And  user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    And  user waits until "signature" modal is closed
    And  user clicks on "Bestätigen" button
    Then user is on the IBAN form page

    # Step 5
    When user enters their iban data
    And  user clicks on "Weiter" button
    Then user is on the mandate register page

    # Step 6
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Finalize
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

  @stagings_only
  @desktop_only
  @cms
  Scenario: Miles and more Mandate registers sees the cockpit
    Given user is as the following
      | first_name | last_name   | password | birthdate  | address_line1   | house_number | place     | zip_code | phone_number  |
      | Clark      | Automation  | Test1234 | 01.01.1970 | Goethestraße,10 |           10 | Frankfurt |    60313 |    1724568899 |

    When user navigates to milesandmore page
    And  the local storage item clark-experiments has the following values
      | 2020Q4DemandcheckPrimer | control |
    And  user clicks on "Registrieren" link
    Then user is on the Miles and More form page
    And  user sees mamcard input field

    # Step 1
    When user clicks on "Überspringen" button
    Then user is on the mandate funnel status page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    When user clicks on "Weiter" button
    Then user is on the phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user is on the phone verification page
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
    And  user sees contract card "Gesetzliche Krankenversicherung - AOK Baden-Württemberg"

    #Step 7
    When user clicks on "Bitte hinterleg deine Miles & More Kartennummer" link
    Then user is on the Miles and More page
    And  user sees mamcard input field


  @desktop_only
  @cms
  Scenario: Mandate registers via incentive funnel and sees the cockpit
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1 | house_number | place     | zip_code | phone_number |
      | CIncetive  |  funnel    | Test1234 | 01.01.1970 | Goethestraße  | 10           | Frankfurt | 60313    | 15166318279  |

    When user navigates to fairtravel page
    And  the local storage item clark-experiments has the following values
      | 2020Q4DemandcheckPrimer | control |
    Then user is on the mandate funnel status fairtravel page
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    # Step 1
    When user clicks on "Weiter" button
    Then user is on the phone verification page
    And  user sees "1 of 5" step number label
    And  user sees 4 trust icons

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user is on the phone verification page
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees "2 of 5" step number label
    And  user sees categories list
    And  user sees search input field

    When user enters "priva" into search input field
    And  user selects "Privathaftpflicht" targeting option
    Then user is on the company selection page
    And  user is on the "Privathaftpflicht" category company targeting path
    And  user sees search input field

    When user enters "allianz" into search input field
    Then user sees the company search results

    When user selects "Allianz Versicherung" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Privathaftpflicht" category and "Allianz Versicherung" company

    When user clicks on "Weiter" button
    Then user is on the profiling page
    And  user sees "3 of 5" step number label
    And  user sees that "mandate document" link is not visible

    # Step 3
    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the confirming page
    And  user sees text "Dein Einverständnis"

    # Step 4
    When user clicks on "OK" button
    And  user waits until "Dein Einverständnis" modal is closed
    Then user sees "4 of 5" step number label
    And  user sees that "Bestätigen" button is disabled

    When user clicks on "Jetzt unterschreiben" button
    And  user enters their signature
    And  user clicks on "Weiter" button
    And  user waits until "signature" modal is closed
    And  user selects incentive funnel condition checkbox
    And  user selects incentive funnel consent checkbox
    Then user sees that "Bestätigen" button is visible

    When user clicks on "Bestätigen" button
    Then user is on the mandate register page
    And  user sees "5 of 5" step number label

    # Step 5
    When user enters their password data
    And  user clicks on "Registrierung abschließen" button
    Then user is on the finished page

    # Finalize
    When user clicks on "Zur Übersicht" button
    Then user is on the manager page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"
