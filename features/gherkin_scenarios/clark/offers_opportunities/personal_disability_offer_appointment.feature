@smoke
@javascript
Feature: Personal disability insurance offer appointment
  As a user
  I want to be able to request an offer appointment for Personal Disability Insurance

  @requires_mandate
  Scenario: user requests an offer appointment for Personal Disability Insurance
    Given user logs in with the credentials and closes "start demand check" modal

    # Navigate to select category page
    When user clicks on "Angebote" link
    Then user is on the select category page
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # Remove the instances of the button "Angebot anfordern".
    # The route "offer.request" does not have it.
    ##
    # And  user sees that "Angebot anfordern" button is disabled
    And user sees category search input field

    # Select category, check consent page and navigate to the questionnaire
    When user enters "beruf" into category search input field
    And  user selects "Berufsunfähigkeitsversicherung" category option
    # https://clarkteam.atlassian.net/browse/JCLARK-61547
    # And  user clicks on "Angebot anfordern" button
    And  user is on the questionnaire page
    And  user sees text "Berufs­un­fä­hig­keits­ver­si­che­rung"
    Then user sees that "Belehrung nach §19 Abs. 5 VVG" "de/anzeigepflicht" link is visible

    When user clicks on "Weiter" button
    Then user sees "Was ist dein höchster Bildungsabschluss?" question label

    # Questionnaire 1
    When user selects "Meister" questionnaire option
    Then user sees "Was machst du beruflich?" question label

    # Questionnaire 2
    When user enters "Engineer" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Wie hoch war dein letztes Jahresbruttoeinkommen?" question label

    # Questionnaire 3
    When user enters "60000" into answer input field
    And  user clicks on "Weiter" button
    Then user sees "Für wie viele Mitarbeiter trägst du Verantwortung?" question label

    # Questionnaire 4
    When user selects "Bis zu 10" questionnaire option
    Then user sees "Wie hoch ist der Anteil deiner Bürotätigkeit?" question label

    # Questionnaire 5
    When user selects "50% bis 80%" questionnaire option
    Then user sees "Bist du Raucher?" question label

    # Questionnaire 6
    When user selects "Nein" questionnaire option
    Then user sees "Hast du noch weitere Anmerkungen?" question label

    # Questionnaire 7
    When user enters "No" into answer input field
    And  user clicks on "Weiter" button

    # Appointment form
    When user selects "next business" day in calendar
    And  user selects "20:00" as appointment time
    And  user clicks on "Absenden" button
    Then user is on the manager page

    # Skip below steps in mobile browser
    Given skip below steps in mobile browser

    # open OPS UI and navigate to appointments page
    Given admin is logged in ops ui

    When admin clicks on "Termine" link
    Then admin is on the appointments page

    # open mandate details view
    When admin clicks on the test appointment id in a table
    Then admin is on the appointment_details page
    And  admin sees table with populated data present on page

    # Check opportunities section
    When admin clicks on "Gelegenheiten" link
    Then admin is on the opportunities page

    # open opportunity details view
    When admin clicks on the test opportunity id in a table
    Then admin is on the opportunity details page
    # Check general mandate information
    And  admin sees the section with general user information
    And  admin sees that opportunity details page contains appointments table with 1 rows
    And  admin sees that opportunity details page contains appointments table with "Beginn 20:00" in column 5 of row 1
