@javascript
@desktop_only
Feature: Order a new product in opsui
  As a user
  I want to be able to order a new product

  @stagings_only
  @requires_mandate
  Scenario: consultant orders a new product for customer
    Given user logs in with the credentials and closes "start demand check" modal

   # Pretargeting
    When user clicks on "Angebote" link
    Then user is on the select category page
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user sees that "Angebot anfordern" button is disabled
    And  user sees category search input field

  # Category targeting
    When user enters "recht" into category search input field
    And  user selects "Rechtsschutzversicherung" category option
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

  # Login to opsui navigate to mandates page
    Given admin is logged in ops ui

  # navigate to mandates page
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # Open first mandate in the table
    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # Open first product in the table without product id
    When admin clicks on "angebotenes Produkt" link
    Then admin is on the product_details page

    When admin clicks on "bearbeiten" link
    Then admin is on the edit product page
    And  admin enters "11122050" into Vertragsende input field

    # Click apply and assert existing documentation
    When admin clicks on "aktualisieren" button
    Then admin is on the product_details page
    And  admin remembers the number of existing documents

    # Order product and assert required documentation
    When admin clicks on "Bestellung vorbereiten" button
    And  admin clicks on "Fortfahren" button
    Then admin sees text "Prepare order succeded."
    And  admin sees that the number of documents increased by 2
