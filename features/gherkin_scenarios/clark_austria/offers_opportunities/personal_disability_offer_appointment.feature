@smoke
@javascript
Feature: Personal disability insurance offer appointment
  As a user
  I want to be able to request an offer appointment for Personal Disability Insurance

  @requires_mandate
  @SEVERITY:blocker
  Scenario: user requests an offer appointment for Personal Disability Insurance
    Given user logs in with the credentials and closes "start demand check" modal

  # Pretargeting
    When user clicks on "Angebote" link
    Then user is on the select category page
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user sees that "Angebot anfordern" button is disabled
    And user sees category search input field

  # Category targeting
    When user enters "beruf" into category search input field
    And  user selects "Berufsunfähigkeitsversicherung" category option
    # And  user clicks on "Angebot anfordern" button
    And  user clicks on "Weiter" button
    And  user is on the questionnaire page
    Then user sees "Bist du Raucher?" question label

  # Questionnaire 1
    When user selects "Nein" questionnaire option
    Then user sees "Wie lautet deine genaue Berufsbezeichnung?" question label

  # Questionnaire 2
    When user enters "Engineer" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Wie ist dein beruflicher Status?" question label

  # Questionnaire 3
    When user selects "Angestellter" questionnaire option
    Then user sees "Was ist dein höchster Ausbildungsgrad?" question label

  # Questionnaire 4
    When user selects "Abschluss Uni / FH" questionnaire option
    Then user sees "Wie hoch war dein letztes Jahresbruttoeinkommen (€)?" question label

  # Questionnaire 5
    When user enters "60000" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Hast du Personalverantwortung?" question label

  # Questionnaire 6
    When user selects "Nein" questionnaire option
    Then user sees "Was bist du bereit monatlich für eine gute Berufsunfähigkeitsversicherung auszugeben?" question label

  # Questionnaire 7
    When user selects "€ 50 - 75" questionnaire option
    Then user sees "Wie hoch ist der Anteil deiner Bürotätigkeit (%)?" question label

  # Questionnaire 8
    When user enters "70" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Hast du noch weitere Informationen oder Anmerkungen für uns?" question label

  # Questionnaire 9
    When user enters "No" into answer input field
    And  user clicks on "Angebot anfordern" button

  # Skip below steps in mobile browser
    Given skip below steps in mobile browser

  # open OPS UI and navigate to appointments page
    Given admin is logged in ops ui

  # Check opportunities section
    When admin clicks on "Gelegenheiten" link
    Then admin is on the opportunities page

  # open opportunity details view
    When admin clicks on the test opportunity id in a table
    Then admin is on the opportunity details page
  # Check general mandate information
    And  admin sees the section with general user information
