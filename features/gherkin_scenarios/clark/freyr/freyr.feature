@smoke
@javascript
@enable_tracking_scripts
@desktop_only
Feature: N26 user starts using Clark app
  As a N26 user
  I see a link to convert to a Clark user
  After I click the link i navigate to freyr funnel, add my email id and complete funnel to become Clark customer

  @requires_mandate
  Scenario: N26 user enter email in the freyr funnel
    When user navigates to freyr funnel page
    And  user is on the freyr funnel page

    When user enters their email data
    And  user clicks on "Bestätigen" button
    Then user sees text "Diese Kunde nicht zulässig"

    When clark updates owner to "n26"
    And  user enters their email data
    And  user clicks on "Bestätigen" button
    Then user is on the freyr success page
    And  "user" receives an email with the content "verifiziere bitte deine E-Mail Adresse"

    When  user clicks "migration_instructions" link from email
    Then  user is on the freyr phone verification page

    When user enters their phone number data
    And  user clicks on "Code senden" button
    Then user is on the freyr phone verification token page

    When user enters their verification token data
    Then user is on the freyr password reset page

    When user enters "Test1234" into Neues Passwort input field
    And  user enters "Test1234" into Passwort wiederholen input field
    And user clicks on "Bestätigen" button
    Then user is on the freyr confetti page

    When user clicks on "Zum Login" link
    Then user is on the app login page

    When user enters their email data
    And user enters "Test1234" into Passwort input field
    And user clicks on "Einloggen" button
    Then user is on the manager page
