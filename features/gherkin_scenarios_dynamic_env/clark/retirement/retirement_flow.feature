@smoke
@javascript
@enable_tracking_scripts
Feature: Retirement flow
  As a Clark user
  I want to be able to do the Rentencheck

  @stagings_only
  @requires_mandate
  Scenario: Mandate registers and do the rentencheck
    Given user logs in with the credentials and closes "start demand check" modal

    # Perform Rentencheck
    When user clicks on "rentencheck" button
    Then user is on the Rentencheck intro page

    When user clicks on "Rentencheck starten" button
    Then user is on the rentencheck questionnaire page
    And  user sees "Was machst du beruflich?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Angestellter" questionnaire option
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page

    When clark version is "control" and cockpit preview experiment is set to "control" variation
    Then user sees retirement card "Gesetzliche Rente"

    # Check Modals
    When user clicks on retirement product card "Gesetzliche Rente"
    Then user is on the data self assertion page

    When user clicks on "Wo finde ich die benötigten Informationen?" link
    Then user sees "info" modal

    When user closes "info" modal
    And  user clicks on "Ich kann meine Renteninformation nicht finden" link
    Then user sees text "Die benötigten Informationen findest du auf deinem Rentenbescheid."

    When user clicks on "Zurück zur Rentenübersicht" link
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Rente"

    # Add data to the Retirement product
    When user clicks on retirement product card "Gesetzliche Rente"
    Then user is on the data self assertion page

    When user enters "2000" into guaranteed pension input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Rente"

    # Retirement wizard new product
    When user clicks on "produkte hinzufugen" button
    Then user is on the input details page
    And  user sees that "Speichern" button is disabled

    When user clicks on "Analyse Service" link
    Then user is on the upload documents page

    When user uploads retirement document
    Then user sees that "Speichern" button is visible

    When user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Mein Rentenprodukt 01"
    And user sees recommendation cards
      | recommendation cards         |
      | Private Altersvorsorge       |
      | Betriebliche Altersvorsorge  |

    # Check recommendation cards
    When user clicks on recommendation card "Private Altersvorsorge"
    Then user is on the retirement single recommendation page
    And  user sees the statistics map
    And  user sees category importance tag label
    And  user sees that "Unverbindliches Angebot anfordern" button is visible

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page

    When user clicks on "Weiter" button
    Then user sees "Was ist dir wichtiger: Flexibilität oder staatliche Zulagen?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Flexibilität" questionnaire option
    Then user sees "Was ist dir bei den Chancen und Risiken einer privaten Altersvorsorge am Wichtigsten?" question label

    When user selects "Je höher die Garantie desto besser" questionnaire option
    Then user sees "Was würdest du aktuell pro Monat für deine private Altersvorsorge investieren?" question label

    When user selects "100 - 200 Euro" questionnaire option
    Then user sees "Hast du noch weitere Anmerkungen?" question label

    When user enters "nothing" into answer input field
    And  user clicks on "Weiter" button
    And  user selects "next business" day in calendar
    And  user selects "default" as appointment time
    And  user clicks on "Absenden" button
    Then user is on the retirement cockpit page
    And  user sees scheduled appointment card

    When user clicks on recommendation card "Betriebliche Altersvorsorge"
    Then user is on the retirement single recommendation page
    And  user sees the statistics map
    And  user sees category importance tag label
    And  user sees that "Unverbindliches Angebot anfordern" button is visible

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page

    When user clicks on "Weiter" button
    Then user sees "Hast du von deinem Arbeitgeber bereits ein Angebot erhalten oder eine Absicherung in diesem Bereich?" question label

    When user selects "Nein" questionnaire option
    Then user sees "Für welches Unternehmen bist du derzeit tätig?" question label

    When user enters "Clark" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Welchen Betrag kannst du monatlich für deine betriebliche Altersvorsorge sparen?" question label

    When user selects "100 - 200 Euro" questionnaire option
    Then user sees "Hast du noch weitere Informationen oder Anmerkungen für uns?" question label

    When user enters "nothing" into answer input field
    And  user clicks on "Weiter" button
    And  user selects "next business" day in calendar
    And  user selects "default" as appointment time
    And  user clicks on "Absenden" button
    Then user is on the retirement cockpit page
    And  user sees scheduled appointment card

  @requires_mandate
  Scenario: Mandate sees out of scope page when job is not in scope
    Given user logs in with the credentials and closes "start demand check" modal

    When user clicks on "rentencheck" button
    Then user is on the Rentencheck intro page

    When user clicks on "Rentencheck starten" button
    Then user is on the rentencheck questionnaire page
    And  user sees "Was machst du beruflich?" question label

    When user selects "Freiberufler" questionnaire option
    And  user clicks on "Weiter" button
    Then user is on the out of scope page

    When user clicks on "Aktualisiere deinen Rentencheck" link
    Then user is on the Rentencheck intro page

    When user clicks on "Rentencheck starten" button
    Then user is on the rentencheck questionnaire page
    And  user sees "Was machst du beruflich?" question label

    When user selects "Beamter" questionnaire option
    And  user clicks on "Weiter" button
    Then user is on the out of scope page

  Scenario: Mandate sees out of scope page when age is > 67
    Given user is as the following
      | birthdate  |
      | 01.01.1950 |

    And  user completes the mandate funnel with an inquiry
      | category                 | company              |
      | Rechtsschutzversicherung | Allianz Versicherung |

    And  user logs in with the credentials and closes "start demand check" modal

    When user clicks on "Rente" link
    Then user is on the out of scope page

    When user clicks on "Zur Versicherungsübersicht" button
    Then user is on the manager page

  @requires_mandate
  Scenario: User completes demand check, sees the retirement cockpit and creates an appointment
    Given user logs in with the credentials and closes "start demand check" modal

    # Start DemandCheck
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

    # Navigate to Retirement cockpit
    When user closes "first recommendation" modal
    And  user clicks on "Rente" link
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Rente"

    # Appointment form
    Then  user sees consultant image
    And  user sees text "Alexander Schecher"
    And  user sees text "Denke an deine Zukunft und sorge vor. Starte jetzt und lass dich von unserem Experten unterstützen!"
    And  user sees that "Vereinbare deinen Beratungstermin" link is visible

    When  user clicks on "Vereinbare deinen Beratungstermin" link
    Then user is on the appointment form page

    When  user navigates back to previous page
    Then user is on the retirement cockpit page

    When  user clicks on "Vereinbare deinen Beratungstermin" link
    Then user is on the appointment form page

    When user selects "next business" day in calendar
    And  user selects "default" as appointment time
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees scheduled appointment card
