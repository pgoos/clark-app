@smoke
@javascript
Feature: Mandate Registration Flow
  As a new organic user
  I want to be able to register and see my cockpit
  After I finish the steps I will become a user

  Scenario: Mandate registers sees the cockpit
    Given user is as the following
      | first_name | last_name  | password | birthdate  | address_line1   | house_number | place     | zip_code | phone_number |
      | Clark      | Automation | Test1234 | 01.01.1970 | Goethestraße,10 | 10           | Vienna    | 2100     | 720778038    |

    When user navigates to first page of mandate funnel
    Then user sees app page header is visible
    And  user sees that "Verträge" link is not visible
    And  user sees that "Bedarf" link is not visible
    And  user sees that "Freunde einladen" link is not visible
    And  user sees that "Rente" link is not visible
    And  user sees text "Dein digitaler Versicherungsmakler für alle deine Verträge"

    # Step 1
    When user clicks on "Weiter" button
    Then user is on the phone verification page
    And  user sees "1 of 5" step number label
    And  user sees 1 trust icons
    And  user sees "+43" country code label

    When user enters their phone number data
    And  user clicks on "Code senden" button
    And  user enters their verification token data
    Then user is on the cockpit preview page

    # Step 2
    When user clicks on "Versicherungen hinzufügen" button
    Then user is on the targeting selection page
    And  user sees "2 of 5" step number label

    # TODO: Ignored since not yet implemented, will un ignore once its live - JCLARK-57784
    #And  user sees categories list
    And  user sees search input field

    When user enters "priva" into search input field
    And  user selects "Privathaftpflichtversicherung" targeting option
    Then user is on the company selection page
    And  user is on the "Privathaftpflichtversicherung" category company targeting path
    And  user sees search input field

    When user enters "allianz" into search input field
    Then user sees the company search results

    When user selects "Allianz" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Privathaftpflichtversicherung" category and "Allianz" company

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
    And  user sees that "Freunde einladen" link is visible
    And  user sees contract card "Privathaftpflichtversicherung - Allianz"

    # Demand Check Section
    When the local storage item clark-experiments has the following values
      | business-strategy                | control          |
      | 2020Q3DemandcheckIntro           | control          |
    And  user clicks on "Bedarf" link
    And  user clicks on "Bedarfscheck starten" button
    Then user is on the demand check page
    And  user sees "Wo wohnst du" question label

    # Question 1
    When user selects "In einer gemieteten Wohnung" questionnaire option
    Then user sees "Planst du, in den nächsten 6 Monaten ein Haus zu bauen?" question label

    # Question 2
    When user selects "Ja" questionnaire option
    Then user sees "Besitzt du eines der folgenden Fahrzeuge?" question label

    # Question 3
    When user selects questionnaire options
      | option   |
      | Anhänger |
      | Motorrad |
    And  user clicks on "Weiter" button
    Then user sees "Wie ist deine Familiensituation?" question label

    # Question 4
    When user selects "Ich lebe alleine" questionnaire option
    Then user sees "Hast du Kinder?" question label

    # Question 5
    When user selects "Nein" questionnaire option
    Then user sees "Was machst du Was ist deine Berufsgruppe?" question label

    # Question 6
    When user selects "Angestellter oder Arbeiter" questionnaire option
    Then user sees "Was machst du gerne in deiner Freizeit?" question label

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
    Then user sees "Wie hoch ist dein letztes Jahresbruttogehalt?" question label

    # Question 9
    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the recommendations page

    When user closes "first recommendation" modal
    When user opens profile menu
    And  user clicks on "Ausloggen" link
    Then user is on the home page
