@smoke
@javascript
@enable_tracking_scripts
Feature: Password reset flow
  As a customer
  I want to be able to reset the password

  @cms
  @requires_mandate
  Scenario: user resets the password
    Given user navigates to home page
    And   user is on the home page
    #Login
    When user opens cms burger menu [mobile view only]
    And  user clicks on "Einloggen" link
    Then user is on the login page
    And  user clicks on "Passwort vergessen?" link
    Then user is on the reset password page

    #Password overlay
    When user enters their email data
    And  user clicks on "Neues Passwort anfordern" button
    Then user is on the reset password page
    And  user sees text "Vielen Dank, bitte überprüfe deinen Posteingang!"

    When "user" receives an email with the content "Du hast dein Passwort vergessen?"
    And  user clicks "reset-password" link from email
    Then user is on the reset password page

    And  user enters "Test12345" into Neues Passwort input field
    And  user enters "Test12345" into Passwort wiederholen input field
    And  user clicks on "Passwort aktualisieren" button
    Then user is on the manager page
