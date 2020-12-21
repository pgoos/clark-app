@javascript
Feature: Private Liability Optimization Page Offer Automation
  As a user
  I want to be able to request an offer and checkout the offer from the optimizations page

  @stagings_only
  @requires_mandate
  Scenario: user optimizes private liability with offer automation
    Given user logs in with the credentials and closes "start demand check" modal
    And   user completes the demand check
    And   user closes "first recommendation" modal
    And user clicks on "Mehr anzeigen" button

    # Privathaftpflicht Category
    When user clicks on recommendation card "Privathaftpflicht"
    Then user is on the single recommendation page
    And  user sees "Privathaftpflicht" category title label

    When user clicks on "Unverbindliches Angebot anfordern" button
    And  user is on the questionnaire page
    And  user sees text "Pri­vat­haft­pflicht"
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    # Questionnaire 1
    When user clicks on "Weiter" button
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
    When user clicks on "Angebot anfordern" button
    Then user is on the offer view page

    # Offer checkout
    When user clicks on "bestellen" button
    Then user is on the checkout start date page
    And user sees text "Deine Daten"
    And user sees text "Gewünschter Versicherungsbeginn"
    And user sees text "Vorschäden"
    And user sees text "Hattest du in den letzten 5 Jahren Schäden in der"
    And user sees text "Bitte antworte wahrheitsgemäß"
    And user sees text "Der Versicherer kann ansonsten"
    And user sees text "z. B. die Leistung verweigern"

    # Start date step
    When user selects "Nächster Werktag" radio button for insurance start date
    And user selects "Nein" radio button for previous damage
    And user clicks on "Weiter" button
    Then user is on the checkout payment details page
    And user sees text "Bankverbindung"

    # Payment details step
    When user enters their iban data
    And  user selects reassurance checkbox
    And  user clicks on "Weiter" button
    Then user is on the checkout offer overview page
    And  user sees text "Mit Klick auf “Zum Abschluss” bestätige ich das"
    And  user sees text "Deine Versicherung"
    And  user sees text "Deine Angaben"
    And  user sees text "Deine Zahlungsdaten"
    And  user sees text "Bestehende Versicherung"
    And  user sees text "Um eine Doppelversicherung zu vermeiden, kündigen wir eine eventuell bestehende Versicherung."

    # Offer overview step
    When user clicks on "Zum Abschluss" button
    Then user is on the checkout order confirmation page
    And  user sees text "Vielen Dank"
    And  user sees text "Deine gewünschte Versicherung wurde beantragt. Du hast eine Bestätigung per E-Mail erhalten!"

    # Checkout order confirmation
    When user clicks on "Zur Vertragsübersicht" link
    Then user is on the manager page

    When user closes "rate us" modal
    And  user sees contract card "Privathaftpflicht"

    # Check recommendations page is updated
    When user clicks on "Bedarf" link
    Then user is on the recommendations page
    But  user doesn't see recommendation card "Privathaftpflicht"
