Feature: Existing offers can be viewed when clicking corresponding recommendation card
  As a Clark user
  I want to be able to view an existing offer when clicking on recommendation card

  @desktop_only
  @requires_mandate
  Scenario: user is taken to the offer page when clicking recommendation card with offer in place
    Given user logs in with the credentials and closes "start demand check" modal
    And   user completes the demand check
    And   user closes "first recommendation" modal
    And   user clicks on "Mehr anzeigen" button

    # Privathaftpflicht Category
    When user clicks on recommendation card "Privathaftpflicht"
    Then user is on the single recommendation page
    And  user sees "Privathaftpflicht" category title label

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page
    And  user sees text "Pri­vat­haft­pflicht"
    And  user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    # Questionnaire 1
    When user clicks on "Weiter" button
    Then user sees "Wen möchtest du versichern?" question label
    And  user sees that "Weiter" button is disabled

    # Previous Answer & Questionnaire 2
    When user selects "Mich alleine" questionnaire option
    Then user sees "Trifft einer der aufgeführten Fälle auf dich zu?" question label

    # Previous Answer & Questionnaire 3
    When user selects "Keiner der Fälle trifft auch mich zu" questionnaire option
    Then user sees "Möchtest du bei einem Schadensfall einen Teil selbst bezahlen?" question label

    # Previous Answer & Questionnaire 4
    When user selects "Im Falle eines Schadens soll meine Geldbörse nicht belastet werden" questionnaire option
    Then user sees "Hast du noch weitere Informationen oder Anmerkungen für uns?" question label

    # Last Answer
    When user clicks on "Angebot anfordern" button
    Then user is on the offer view page

    # Check offer page accessed from recommendation overview page
    When  user clicks on "Bedarf" link
    Then user is on the recommendations page

    When user clicks on "Mehr anzeigen" button
    And  user clicks on recommendation card "Privathaftpflicht"
    Then user is on the offer view page
    And  user sees text "Deine Angebote zur Pri­vat­haft­pflicht"
