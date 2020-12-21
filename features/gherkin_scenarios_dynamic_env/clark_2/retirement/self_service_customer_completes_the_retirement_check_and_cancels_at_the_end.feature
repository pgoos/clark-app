@javascript
@smoke
Feature: Self-service customer completes retirement check and then cancels
  As a self-service customer
  I want to complete retirement check and then cancel

  Scenario: Self-service customer completes retirement check and cancels at the end
    Given user is as the following
      | first_name |
      | Clark 2.0  |

    When user navigates to clark 2 starting page
    Then user is on the clark 2 contract adding exploration page

    When user clicks on "Rente" link
    Then user is on the clark 2 temporary retirement page
    And  user sees text "Berechne deine Netto-Rente in nur 2 Minuten. Beantworte jetzt Fragen zu deiner Situation und erfahre, wie gut deine Altersvorsorge ist."

    When user clicks on "Jetzt starten" link
    Then user is on the rentencheck questionnaire page
    And  user sees "Wann bist du geboren?" question label

    When user enters "01.01.1980" into birth date input field
    And  user clicks on "Weiter" button
    Then user sees "Was ist dein Geschlecht?" question label

    When user selects "Männlich" questionnaire option
    Then user sees "Was machst du beruflich?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Angestellter" questionnaire option
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch ist dein Jahresbruttogehalt?" question label

    When user enters "60000" into answer input field
    And  user clicks on "Speichern" button
    Then user is on the clark 2 registration page
    And  user sees text "Sichere deinen Fortschritt"
    And  user sees email address input field
    And  user sees password input field

    When user enters their email address data
    And  user enters their password data
    And  user clicks on "Jetzt registrieren" button
    Then user is on the clark 2 retirement rewards page
    And  user sees text "Geschafft!"

    When user clicks on "Vorläufige Prognose ansehen" link
    Then user is on the retirement cockpit page
    And  user sees retirement card "Gesetzliche Rente"

    When user clicks on retirement product card "Gesetzliche Rente"
    Then user is on the data self assertion page

    When user clicks on "Analyse Service" link
    Then user is on the upload documents page

    When user uploads retirement document
    Then user sees that "Speichern" button is visible

    When user clicks on "Abbrechen" button
    Then user is on the retirement cockpit page
