@smoke
@javascript
Feature: Invite a friend
  As a user
  I want to be able to login and invite a friend

  @requires_mandate
  @cms
  Scenario: user invites a friend to clark
    Given user logs in with the credentials and closes "start demand check" modal

    When user opens profile menu
    And  user clicks on "Freunde einladen und 50€ erhalten" link
    Then user is on the invite friend page

    # Invite a friend's email address
    When user enters their invitee email data
    And  user clicks on "E-Mail senden" button
    Then user sees text "erfolgreich versendet"
    And "user's friend" receives an email with the content "hat dich zu CLARK eingeladen"

    # Copies the invitation link
    When user clicks on "Link kopieren" button
    Then user sees text "erfolgreich kopiert"
