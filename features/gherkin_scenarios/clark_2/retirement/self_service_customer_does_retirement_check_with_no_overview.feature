@javascript
Feature: self service customer completes retirement check
  As a self service customer
  I want to complete retirement check but no overview is available for me

  Scenario: Self service customer completes the retirement check with overview not available
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

    When user clicks on calendar icon
    And  user clicks on "Weiter" button
    Then user sees "Was ist dein Geschlecht?" question label

    When user selects "Männlich" questionnaire option
    Then user sees "Was machst du beruflich?" question label
    And  user sees that "Weiter" button is disabled

    When user selects "Freiberufler" questionnaire option
    And  user clicks on "Weiter" button

    Then user is on the out of scope page
