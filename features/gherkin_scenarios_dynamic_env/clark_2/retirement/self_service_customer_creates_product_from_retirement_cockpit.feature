@javascript
@smoke
Feature: self service customer creates a new product from retirement cockpit
  As a self service customer
  I want to complete retirement check and then add a product

  Scenario: self service customer adds a product from retirement cockpit
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

    When user clicks on "produkte hinzufugen" button
    Then user is on the input details page

    When user selects "Private Altersvorsorge" option in Rentenart dropdown
    And  user selects "Basis-Rentenversicherung" option in Renten-Kategorie dropdown
    And  user enters "Allianz Lebensversicherungs-Aktiengesellschaft" into retirement company input field
    And  user selects "next business" day in calendar
    And  user enters "3.000" into Monatliches Renteneinkommen inkl. Überschüssen input field
    And  user clicks on "Speichern" button
    Then user is on the retirement cockpit page
    And  user sees retirement card "Basis-Rentenversicherung"

    When user clicks on "Verträge" link
    Then user is on the manager page
    And  user sees contract card "Basis-Rentenversicherung - Allianz Versicherung"

    # Navigate the contract details page and check content of the page
    When user clicks on contract card "Basis-Rentenversicherung"
    Then user is on the clark 2 contract details page
    And  user sees text "Bitte Vertrag hochladen"
    And  user sees "Basis-Rentenversicherung" contract details title label
    And  user sees "Allianz Versicherung" contract details secondary title label
    And  user sees clark rating section
    And  user sees "3 items" tips and info section

    # Upload documents and check results
    When user uploads contract document
    Then user sees "Geschafft!" modal

    When user closes "Geschafft!" modal
    Then user sees waiting period label
    And  user sees 1 document cards
    But  user doesn't see text "Bitte Vertrag hochladen"
