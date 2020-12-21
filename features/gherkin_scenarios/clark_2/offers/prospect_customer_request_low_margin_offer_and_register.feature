@javascript
Feature: Prospect customer selects category, completes registration and mandate signature to get an offer
  As a Prospect customer
  I want to request an offer after completing register and mandate journey

  @smoke
  Scenario: Self-service customer completes request an instant LM offer
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    When user navigates to clark 2 offer page
    Then user is on the clark 2 select category for offer page

    When user clicks on popular option card "Privathaftpflicht"
    And  user is on the questionnaire page
    And  user sees text "Pri­vat­haft­pflicht"
    And  user sees that "Datenschutzerklärung" "de/datenschutz" link is visible
    And  user sees that "AGB" "de/agb" link is visible
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    # Questionnaire 1
    And  user clicks on "Weiter" button
    Then user sees "Wen möchtest du versichern?" question label
    And  user sees that "Weiter" button is disabled

  # Previous Answer & Questionnaire 2
    When user selects "Mich alleine" questionnaire option
    Then user sees "Trifft einer der aufgeführten Fälle auf dich zu?" question label

  # Previous Answer & Questionnaire 3
    When user selects "Keiner der Fälle trifft auch mich zu" questionnaire option
    Then user sees "Möchtest du bei einem Schadensfall einen Teil selbst bezahlen?" question label

  # Previous Answer & Questionnaire 4
    When user selects "Im Falle eines Schadens soll meine Geldbörse nicht belastet werden" questionnaire option
    Then user sees "Hast du noch weitere Informationen oder Anmerkungen für uns?" question label

  # Last Answer
    And  user clicks on "Angebot anfordern" button
    Then user is on the clark 2 offer rewards page

    When user clicks on "Zum Angebot" link
    Then user is on the offer view page

  # Offer checkout
    When user clicks on "bestellen" button
    Then user is on the clark 2 registration page
    And  user sees text "Sichere deinen Fortschritt"
    And  user sees email address input field
    And  user sees password input field

    When user enters their email address data
    And  user enters their password data
    And  user clicks on "Jetzt registrieren" button
    Then user is on the checkout profiling page
    And user sees text "Persönliche Angaben"
    And user sees that Deine Daten checkout step is active

    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the checkout start date page
    And user sees that Startdatum checkout step is active
    And user sees text "Gewünschter Versicherungsbeginn"
    And user sees text "Vorschäden"
    And user sees text "Hattest du in den letzten 5 Jahren Schäden in der"
    And user sees text "Bitte antworte wahrheitsgemäß"
    And user sees text "Der Versicherer kann ansonsten"
    And user sees text "z. B. die Leistung verweigern"

    # Start date step
    When user selects "Ja, ich hatte Schäden" radio button for previous damage
    And user enters random string into previous damage input field
    And user selects "Später" radio button for insurance start date
    And user selects "next business" day in calendar
    And user clicks on "Weiter" button
    Then user is on the checkout payment details page
    And user sees that Zahlungsdaten checkout step is active
    And user sees text "Bankverbindung"

     # Payment details step
    When user enters their iban data
    And  user selects reassurance checkbox
    And  user clicks on "Weiter" button
    Then user is on the checkout offer overview page
    And user sees that Übersicht checkout step is active
    And  user sees text "Mit Klick auf “Zum Abschluss” bestätige ich das"
    And  user sees text "Deine Versicherung"
    And  user sees text "Deine Angaben"
    And  user sees text "Deine Zahlungsdaten"
    And  user sees text "Bestehende Versicherung"
    And  user sees text "Bitte kündige eine eventuell bestehende Versicherung."

    # Offer overview step
    When user clicks on "Zum Abschluss" button
    Then user is on the checkout order confirmation page
    And  user sees text "Vielen Dank"
    And  user sees text "Deine gewünschte Versicherung wurde beantragt. Du hast eine Bestätigung per E-Mail erhalten!"

    # Checkout order confirmation
    When user clicks on "Zur Vertragsübersicht" link
    Then user is on the manager page

    When user closes "rate us" modal
    Then user sees contract card "Privathaftpflicht"

  @smoke
  Scenario: Self-service customer completes request a non instant LM offer
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    When user navigates to clark 2 offer page
    Then user is on the clark 2 select category for offer page

    When user clicks on popular option card "Hausrat"
    Then user is on the questionnaire page
    And  user sees text "Haus­rat"
    And  user sees that "Datenschutzerklärung" "de/datenschutz" link is visible
    And  user sees that "AGB" "de/agb" link is visible
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    # Questionnaire 1
    And  user clicks on "Weiter" button
    Then user sees "Wie groß ist die zu versichernde Wohnfläche?" question label
    And  user sees that "Weiter" button is disabled

  # Previous Answer & Questionnaire 2
    When user enters "50" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Wo liegt deine Wohneinheit?" question label

  # Previous Answer & Questionnaire 3
    When user selects "In einem Mehrfamilienhaus" questionnaire option
    Then user sees "Auf welcher Etage wohnst du?" question label

  # Previous Answer & Questionnaire 4
    When user enters "5" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Ist die Adresse aus deinem Clark-Account auch der Versicherungsort?" question label

  # Previous Answer & Questionnaire 5
    When user selects "Ja" questionnaire option
    Then user sees "Möchtest du neben den Basisrisiken Feuer, Leitungswasser, Sturm und Einbruchdiebstahl weitere Bausteine absichern?" question label

    # Previous Answer & Questionnaire 6
    When user selects "Glasbruch" questionnaire option
    And  user clicks on "Weiter" button
    Then user sees "Wie viele Schäden hattest du in der Hausratversicherung in den letzten 5 Jahren" question label

    # Last Answer
    When user selects "1 Schaden" questionnaire option
    And  user clicks on "Angebot anfordern" button
    Then user is on the clark 2 registration page
    And  user sees text "Sichere deinen Fortschritt"
    And  user sees email address input field
    And  user sees password input field

    When user enters their email address data
    And  user enters their password data
    And  user clicks on "Jetzt registrieren" button
    Then user is on the clark 2 offer upgrade profile page

    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the clark 2 offer rewards page
    When user clicks on "Zu deinen Verträgen" link
    Then user is on the manager page

    Then user sees contract card "Hausrat"
    And  user sees text "Angebot wird erstellt"
