@smoke
@javascript
Feature: Legal Protection Offer Automation
  As a user
  I want to be able to request an offer and checkout the offer

  @stagings_only
  @requires_mandate
  Scenario: user creates Legal Protection Offer Automation and checkout the offer
    Given user logs in with the credentials and closes "start demand check" modal

    # Navigate to select category page
    When user clicks on "plus" button
    And  user sees dropdown menu with add contracts options
    And  user clicks on "Neuen Vertrag abschließen" button
    Then user is on the select category page
    And  user sees category search input field

    # Select category, check consent page and navigate to the questionnaire
    When user enters "recht" into category search input field
    And  user selects "Rechtsschutzversicherung" category option
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user clicks on "Angebot anfordern" button
    And  user is on the questionnaire page
    And  user sees text "Rechts­schutz­ver­si­che­rung"
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

  # Questionnaire 1
    When user clicks on "Weiter" button
    And  user selects "Single" questionnaire option
    Then user sees "Bist du im öffentlichen Dienst beschäftigt?" question label

  # Questionnaire 2
    When user selects "Ja" questionnaire option
    Then user sees "Welche Bereiche möchtest du zusätzlich zum privaten Rechtsschutz absichern?" question label

  # Questionnaire 3
    When user selects "Beruf" questionnaire option
    And user clicks on "Weiter" button
    Then user sees "Möchtest du bei einem Schadensfall einen Teil selbst bezahlen?" question label

  # Questionnaire 4
    When user selects "Ja, bis zu 300 Euro" questionnaire option
    And  user clicks on "Angebot anfordern" button
    Then user is on the offer view page

    # Offer checkout
    When  user clicks on "bestellen" button
    Then user is on the checkout start date page
    And user sees that Startdatum checkout step is active
    And user sees text "Startdatum"
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

    # Product details
    When user closes "rate us" modal
    And  user clicks on contract card "Rechtsschutzversicherung"
    Then user is on the product details page
    And  user sees tariff details list

    When user scrolls to upload documents section
    And  user uploads product document
#    Then user sees 6 uploaded document cards ## this step requires additional setup
    And  user sees allgemeine informationen section
    And  user sees expertentipps zur versicherung section
