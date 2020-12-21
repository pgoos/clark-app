@smoke
@javascript
Feature: Legal Protection Offer Automation
  As a user
  I want to be able to request an offer and checkout the offer

  @stagings_only
  @requires_mandate
  @desktop_only
  Scenario: user creates Legal Protection Offer Automation and checkout the offer
    Given user logs in with the credentials and closes "start demand check" modal

   # Pretargeting
    When user clicks on "Angebote" link
    Then user is on the select category page
    And  user sees category search input field

  # Category targeting
    When user enters "recht" into category search input field
    And  user selects "Rechtsschutzversicherung" category option
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user clicks on "Angebot anfordern" button
    And  user clicks on "Weiter" button
    Then user is on the questionnaire page
    And  user sees "Wen möchtest du versichern?" question label
    And  user sees that "Weiter" button is disabled

  # Questionnaire 1
    When user selects "Mich alleine" questionnaire option
    Then user sees "Wie ist deine berufliche Situation?" question label

  # Questionnaire 2
    When user selects "Ich bin als Angestellter tätig" questionnaire option
    Then user sees "Welche Bereiche möchtest du zusätzlich zum Straf-, Schadenersatz-, Sozial- & Vertrags-Rechtsschutz absichern?" question label

  # Questionnaire 3
    When user selects "Arbeit" questionnaire option
    And  user clicks on "Weiter" button
    Then user sees "Wie viele Rechtsschutzschäden hattest du in den letzten 5 Jahren?" question label

  # Questionnaire 4
    When user selects "Keinen" questionnaire option
    Then user sees "Hast du noch weitere Informationen oder Anmerkungen für uns?" question label

    When  user clicks on "Angebot anfordern" button
    Then user is on the offer view page

    # TODO: Ignored since not yet implemented, will un ignore once its live - JCLARK-57784
    #And  user sees "offer" modal
    #And  user sees text "Dein Angebot ist da!"

  # Offer checkout
    #When user clicks on "Zum Angebot" button
    And  user clicks on "bestellen" button
    Then user is on the checkout start date page
    And user sees that Startdatum checkout step is active
    And user sees text "Startdatum"
    And user sees text "Deine Daten"
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
    And  user sees text "Um eine Doppelversicherung zu vermeiden, kündigen wir eine eventuell bestehende Versicherung."

    # Offer overview step
    When user clicks on "Zum Abschluss" button
    Then user is on the checkout order confirmation page
    And  user sees text "Vielen Dank"
    And  user sees text "Deine gewünschte Versicherung wurde beantragt. Du hast eine Bestätigung per E-Mail erhalten!"

    # Checkout order confirmation
    When user clicks on "Zur Vertragsübersicht" link
    Then user is on the manager page

    #Product details
    When user closes "rate us" modal
    And  user clicks on contract card "Rechtsschutzversicherung"
    Then user is on the product details page
    And  user sees tariff details list

    When user scrolls to upload documents section
    And  user uploads product document
#    Then user sees 4 uploaded document cards
    And  user sees allgemeine informationen section
    And  user sees expertentipps zur versicherung section
