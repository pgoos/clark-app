@javascript
Feature: Change the email id and password
  As a user
  I want to be able to login and change the email id and password

  @desktop_only
  @requires_mandate
  Scenario: user changes the email id and password
    Given user logs in with the credentials and closes "start demand check" modal

        # Generate a new email and update the user details
    When user decides to use "random generated value" as a new "email"
    And  user decides to use "Test12345" as a new "password"

    When user opens profile menu
    And  user clicks on "Anmeldedaten" link
    Then user is on the account edit page


    And  user enters their email data
    And  user enters their password data
    And  user enters "Test12345" into Passwort wiederholen input field
    And  user clicks on "Speichern" button
    Then user sees text "Deine Daten wurden erfolgreich aktualisiert"

    # Log out
    When user navigates to manager page
    Then user is on the manager page

    When user opens profile menu
    And  user clicks on "Ausloggen" link
    Then user is on the home page

    # Log in using changed email and password
    When user logs in with the credentials
    Then user is on the manager page
