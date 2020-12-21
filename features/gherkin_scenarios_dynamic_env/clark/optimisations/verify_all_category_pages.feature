@smoke
@javascript
Feature: Verify all categories in recommendations and rente pages
  As a Clark user
  I want to see all recommendations in Bedarf and rente tab

  @stagings_only
  @desktop_only
  @requires_mandate
  Scenario: User sees all recommendations after registration in Bedarf and rente tab
    Given user logs in with the credentials and closes "start demand check" modal
    And   user completes the demand check
    And   user closes "first recommendation" modal

    # Check Importance label on card recommendation (three types)
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user sees that importance label for "Privathaftpflicht" card is "SEHR WICHTIG"
    And  user sees that importance label for "Gesetzliche Krankenversicherung" card is "WICHTIG"
    And  user sees that importance label for "Hausrat" card is "SINNVOLL"

    #Privathaftpflicht Category
    When user clicks on recommendation card "Privathaftpflicht"
    Then user is on the single recommendation page
    And  user sees "Privathaftpflicht" category title label
    And  user sees "SEHR WICHTIG" category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Hausrat versicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Hausrat"
    Then user is on the single recommendation page
    And  user sees "Hausrat" category title label
    And  user sees "SINNVOLL" category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page
    And  user sees text "Haus­rat"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Tierhalter-Haftpflicht Category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Tierhalter-Haftpflicht"
    Then user is on the single recommendation page
    And  user sees "Tierhalter-Haftpflicht" category title label

    When user sees category importance tag label
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #KFZ-Absicherung Category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "KFZ-Absicherung"
    Then user is on the single recommendation page
    And  user sees "KFZ-Absicherung" category title label
    And  user sees category importance tag label

    When user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Berufsunfähigkeitsversicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Berufsunfähigkeitsversicherung"
    Then user is on the single recommendation page
    And  user sees "Berufsunfähigkeitsversicherung" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page
    And  user sees text "Berufs­un­fä­hig­keits­ver­si­che­rung"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Gesetzliche Krankenversicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Gesetzliche Krankenversicherung"
    Then user is on the single recommendation page
    And  user sees "Gesetzliche Krankenversicherung" category title label
    And  user sees "WICHTIG" category importance tag label

    When user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Krankenzusatzversicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Krankenzusatzversicherung"
    Then user is on the single recommendation page
    And  user sees "Krankenzusatzversicherung" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    And  user is on the questionnaire page
    Then user sees text "Kran­ken­zu­satz­ver­si­che­rung"


    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Unfallversicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Unfallversicherung"
    Then user is on the single recommendation page
    And  user sees "Unfallversicherung" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    And  user is on the questionnaire page
    Then user sees text "Unfall­ver­si­che­rung"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Reisekrankenversicherung category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Reiseversicherung"
    Then user is on the single recommendation page
    And  user sees "Reiseversicherung" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    And  user is on the questionnaire page
    Then user sees text "Rei­se­ver­si­che­rung"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Private Altersvorsorge category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Private Altersvorsorge"
    Then user is on the single recommendation page
    And  user sees "Private Altersvorsorge" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    Then user is on the questionnaire page
    Then user sees text "Pri­vate Alters­vor­sorge"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    #Betriebliche Altersvorsorge category
    When user clicks on "Bedarf" link
    And  user clicks on "Mehr anzeigen" button
    Then user is on the recommendations page

    When user clicks on recommendation card "Betriebliche Altersvorsorge"
    Then user is on the single recommendation page
    And  user sees "Betriebliche Altersvorsorge" category title label
    And  user sees category importance tag label

    When user clicks on "Unverbindliches Angebot anfordern" button
    And  user is on the questionnaire page
    Then user sees text "Betrieb­li­che Alters­vor­sorge"

    When user navigates back to previous page
    And  user clicks on "Bestehenden Vertrag hinzufügen" button
    Then user is on the company selection page

    # Check action sheets functionality on recommendation card in "Things" section
    When user clicks on "Bedarf" link
    Then user is on the recommendations page

    When user clicks on "Mehr anzeigen" button
    And  user clicks questionnaire property on recommendation card "Privathaftpflicht"
    Then user is on the questionnaire page
    And  user sees text "Pri­vat­haft­pflicht"

    When user navigates back to previous page
    Then user is on the recommendations page

    When user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Privathaftpflicht"
    And  user clicks on "Mehr Informationen" link
    Then user is on the single recommendation page
    And  user sees "Privathaftpflicht" category title label

    When user navigates back to previous page
    Then user is on the recommendations page

    When user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Privathaftpflicht"
    And  user clicks on "Meinen Vertrag hinzufügen" link
    Then user is on the company selection page

    # Check action sheets functionality on recommendation card in "Health" section
    When user navigates back to previous page
    Then user is on the recommendations page

    When user clicks on "Mehr anzeigen" button
    And  user clicks questionnaire property on recommendation card "Krankenzusatzversicherung"
    Then user is on the questionnaire page
    And  user sees text "Kran­ken­zu­satz­ver­si­che­rung"

    When user navigates back to previous page
    Then user is on the recommendations page

    When  user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Krankenzusatzversicherung"
    And  user clicks on "Mehr Informationen" link
    Then user is on the single recommendation page
    And  user sees "Krankenzusatzversicherung" category title label

    When user navigates back to previous page
    Then user is on the recommendations page

    When  user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Krankenzusatzversicherung"
    And  user clicks on "Meinen Vertrag hinzufügen" link
    Then user is on the company selection page

    # Check action sheets functionality on recommendation card in "Retirement" section
    When user navigates back to previous page
    Then user is on the recommendations page

    When  user clicks on "Mehr anzeigen" button
    And  user clicks questionnaire property on recommendation card "Private Altersvorsorge"
    Then user is on the questionnaire page
    And  user sees text "Pri­vate Alters­vor­sorge"

    When user navigates back to previous page
    Then user is on the recommendations page

    When  user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Private Altersvorsorge"
    And  user clicks on "Mehr Informationen" link
    Then user is on the single recommendation page
    And  user sees "Private Altersvorsorge" category title label

    When user navigates back to previous page
    Then user is on the recommendations page

    When  user clicks on "Mehr anzeigen" button
    And  user clicks ellipses property on recommendation card "Private Altersvorsorge"
    And  user clicks on "Meinen Vertrag hinzufügen" link
    Then user is on the company selection page
