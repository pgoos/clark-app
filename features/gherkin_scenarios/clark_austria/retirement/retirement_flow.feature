@smoke
@javascript
Feature: Retirement flow
  As a Clark Austria user
  I want to be able to do the Rentencheck

  @stagings_only
  @requires_mandate
  Scenario: Mandate registers and do the rentencheck with pension statement
    Given user logs in with the credentials and closes "start demand check" modal

    # Perform Rentencheck
    When user clicks on "pensionscheck" button
    Then user is on the Pensionscheck intro page

    When user clicks on "Pensionscheck starten" button
    Then user is on the rentencheck questionnaire page
    And  user sees "Hast du einen aktuellen Pensionskontoauszug zur Hand?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Ja" questionnaire option
    Then user sees "Von welchem Jahr ist dieser Pensionskontoauszug?" question label

    When user enters "2019" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Wieviele Versicherungsmonate stehen auf deinem Pensionskontoauszug?" question label

    When user enters "120" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist die Gesamtgutschrift auf deinem Pensionskonto?" question label

    When user enters "10000" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Welcher Berufsgruppe gehörst du an?" question label

    When user selects "Angestellter" questionnaire option
    Then user sees "Wie hoch ist dein Bruttoeinkommen pro Kalenderjahr (€)?" question label

    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Alterspension"
    And  user sees that retirement card "Gesetzliche Alterspension" is not clickable
    And  user sees recommendation cards
      | recommendation cards                    |
      | Private Altersvorsorge & Vermögensaufbau|

    When user clicks on recommendation card "Private Altersvorsorge & Vermögensaufbau"
    Then user is on the retirement single recommendation page
    And  user sees category importance tag label
    And  user sees that "Unverbindliches Angebot anfordern" button is visible

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page

    When user clicks on "Weiter" button
    Then user sees "Was ist dir bei den Chancen und Risiken einer privaten Altersvorsorge am wichtigsten: Sicherheit über alles? Oder no risk no fun?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Je höher die Garantie, desto besser" questionnaire option
    Then user sees "Wie wichtig sind dir staatliche Zulagen bzw. Förderungen?" question label

    When user selects "Auf den Staat möchte ich mich bei meinen Planungen gar nicht verlassen." questionnaire option
    Then user sees "Nun zu ein paar harten Fakten: Wie hoch ist dein aktuelles Bruttoeinkommen pro Jahr?" question label

    When user enters "60000" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Was würdest du aktuell maximal für deine private Altersvorsorge investieren?" question label

    When user selects "100 - 200 Euro monatlich" questionnaire option
    Then user sees "Welche Wünsche möchtest du uns zur privaten Altersvorsorge noch mit auf den Weg geben?" question label

    When user enters "nothing" into answer input field
    And  user clicks on "Angebot anfordern" button
    Then user is on the retirement cockpit page

  @stagings_only
  @requires_mandate
  Scenario: Mandate registers and do the rentencheck without pension statement
    Given user logs in with the credentials and closes "start demand check" modal

    When user clicks on "pensionscheck" button
    Then user is on the Pensionscheck intro page

    When user clicks on "Pensionscheck starten" button
    Then user is on the rentencheck questionnaire page
    And  user sees "Hast du einen aktuellen Pensionskontoauszug zur Hand?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Nein" questionnaire option
    Then user sees "Wieviele Monate bist du bereits erwerbstätig?" question label

    When user enters "120" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Welcher Berufsgruppe gehörst du an?" question label

    When user selects "Angestellter" questionnaire option
    Then user sees "Wie hoch ist dein Bruttoeinkommen pro Kalenderjahr (€)?" question label

    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Alterspension"
    And  user sees that retirement card "Gesetzliche Alterspension" is not clickable

    # Retirement inquiry
    When user clicks on "produkte hinzufugen" button
    Then user is on the targeting selection page
    And  user sees "Altersvorsorge" text in search input field

    And  user selects "Private Altersvorsorge & Vermögensaufbau" targeting option
    Then user is on the company selection page

    When user enters "allianz" into search input field
    Then user sees the company search results

    When user selects "Allianz" targeting option
    Then user is on the targeting selection page
    And  user can see inquiry with "Private Altersvorsorge & Vermögensaufbau" category and "Allianz" company

    When user clicks on "Weiter" button
    Then user is on the manager page
    And  user sees contract card "Private Altersvorsorge & Vermögensaufbau - Allianz"

    When user clicks on "Vorsorge" link
    Then user is on the retirement cockpit page

    # Appointment form
    And  user sees consultant image
    And  user sees text "Isabella Haider"
    And  user sees text "Denke an deine Zukunft und sorge vor. Starte jetzt und lass dich von unserem Experten unterstützen!"
    And  user sees that "Vereinbare deinen Beratungstermin" link is visible

    When user clicks on "Vereinbare deinen Beratungstermin" link
    Then user is on the appointment form page

    When user navigates back to previous page
    Then user is on the retirement cockpit page

    When user clicks on "Vereinbare deinen Beratungstermin" link
    Then user is on the appointment form page

    When user selects "next business" day in calendar
    And  user selects "default" as appointment time
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees scheduled appointment card
