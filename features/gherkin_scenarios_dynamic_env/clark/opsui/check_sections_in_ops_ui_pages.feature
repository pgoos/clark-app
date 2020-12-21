@smoke
@javascript
@desktop_only
Feature: Check sections in OPS UI pages
  As an admin
  I want to be sure that all required sections are present in OPS UI pages

  @requires_mandate
  Scenario: Check sections in mandate details page in OPS UI for a newly created mandate
    # open OPS UI and navigate to mandate page
    Given admin is logged in ops ui
    When admin clicks on "Kunden" link
    Then admin is on the mandates page

    # open mandate details view
    When admin clicks on the test mandate id in a table
    Then admin is on the mandate details page

    # check that all required sections are present
    And admin sees the section with general user information
    And admin sees "Verkaufschancen" page section
    And admin sees "Pflicht Empfehlungen" page section
    And admin sees "Leben Aspekt Punktzahl" page section
    And admin sees "Leben Aspekt Priorität" page section
    And admin sees "Partner Products" page section
    And admin sees "Anfrage" page section
    And admin sees "Produkte" page section
    And admin sees "Empfehlungen" page section
    And admin sees "Dokument" page section
    And admin sees "Interaktionen" page section
    And admin sees "beantwortete Fragebögen" page section
    And admin sees "eingeladene Kunden" page section
    And admin sees "Profildaten" page section
    And admin sees Kommentare input field

    # TODO: add scenario for checking 'NPS (Nicht akzeptiert)' section and 'Deed Log Einträge section'

  @stagings_only
  Scenario: Check sections in inquiry details page in OPS UI for a newly created inquiry
    Given user is as the following
      | first_name | last_name      |
      | Clark      | Inquiry Tester |

    When user completes the mandate funnel with an inquiry
      | category                 | company |
      | Rechtsschutzversicherung | Asstel  |

    # open OPS UI and navigate to the inquiries page
    Given admin is logged in ops ui
    When admin clicks on "Anfragen" link
    Then admin is on the inquiries page

    # open inquiry details page
    When admin clicks on the test inquiry id in a table
    Then admin is on the inquiry details page

    # check customer information section
    And admin sees text "Kunde"
    And admin sees text "Status in Erstellung"

    # check company details section
    And admin sees "Asstel" page section
    And admin sees that 3 row of "Asstel" section contains "Details"
    And admin sees that 4 row of "Asstel" section contains "Average response time 24 Tage"
    And admin sees that 8 row of "Asstel" section contains "Kontaktdaten"
    And admin sees that 9 row of "Asstel" section contains "Info phone +4922196777651"

    # check mandate details section
    And admin sees "Kunde" page section
    And admin sees that 1 row of "Kunde" section contains "Vorname Clark"

    # check products and documents sections
    And admin sees "Produkte" page section
    And admin sees "Dokumente" page section

    # check comments input and required buttons
    And admin sees Kommentare input field
    And admin sees that "Hochladen" button is visible
    And admin sees that "löschen" link is visible

  @stagings_only
  @requires_mandate
  Scenario: Check sections in opportunity details page in OPS UI for a newly created opportunity

    # login as a customer and create an opportunity
    Given user logs in with the credentials and closes "start demand check" modal
    When  user clicks on "Angebote" link
    Then  user is on the select category page

    When user enters "private alter" into category search input field
    Then user selects "Private Altersvorsorge" category option
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user clicks on "Angebot anfordern" button
    And  user is on the questionnaire page
    And  user sees text "Pri­vate Alters­vor­sorge"
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    When user clicks on "Weiter" button
    And user selects "Flexibilität" questionnaire option
    Then user sees "Was ist dir bei den Chancen und Risiken einer privaten Altersvorsorge am Wichtigsten?" question label

    When user selects "Je höher die Garantie desto besser" questionnaire option
    Then user sees "Was würdest du aktuell pro Monat für deine private Altersvorsorge investieren?" question label

    When user selects "100 - 200 Euro" questionnaire option
    Then user sees "Hast du noch weitere Anmerkungen?" question label

    When user enters "nothing" into answer input field
    And  user clicks on "Weiter" button

    When user sees text "Wähle einen persönlichen Beratungstermin"
    Then user selects "next business" day in calendar
    And  user selects "default" as appointment time

    When user clicks on "Absenden" button
    Then user is on the manager page

    # open OPS UI, log in as an admin and navigate to opportunities page
    Given admin is logged in ops ui
    When  admin clicks on "Gelegenheiten" link
    Then  admin is on the opportunities page

    # open opportunity details view
    When admin clicks on the test opportunity id in a table
    Then admin is on the opportunity details page

    # Check general mandate information
    And admin sees the section with general user information

    # Check opportunity details section
    And admin sees text "Phase erstellt"
    And admin sees text "erstellt am"
    And admin sees text "geändert am"
    And admin sees text "verantwortlicher Berater"
    And admin sees text "hat HM? false"
    And admin sees text "angerufen Welcome Call nicht versucht"
    And admin sees text "Quelle Fragebogen: Private Altersvorsorge"
    And admin sees text "Termine"
    And admin sees text "Angebot"
    And admin sees text "Produkt / Kategorie"
    And admin sees text "Kategorie Private Altersvorsorge"

    # check other sections
    And admin sees "0 Dokumente" page section
    And admin sees "Neueste Benutzerinteraktion" page section
    And admin sees "1 Interaktionen" page section
    And admin sees Kommentare input field
