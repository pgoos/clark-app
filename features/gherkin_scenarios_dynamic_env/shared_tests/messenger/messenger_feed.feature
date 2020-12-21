@smoke
@javascript
Feature: Communication through messenger
  As a user
  I want to be able to login, send and receive a message by messenger

  @requires_mandate
  Scenario Outline: user opens the messenger and sends a message
    Given user logs in with the credentials and closes "start demand check" modal

    # Open messenger
    When user clicks messenger icon
    Then user sees messenger window opened

    # Send message
    When user enters "<user_message>" into messenger input field
    And user clicks on "messenger send" button
    Then user sees their own "<user_message>" message in the feed

    # Receive message from OPS UI
    Given skip below steps in mobile browser

    When admin receives "<user_message>" message in OPS UI
    And  user receives "<admin_message>" message from admin site
    Then user sees "<admin_message>" admin message in the feed

    Examples:
      | user_message          | admin_message         |
      | This is user message  | This is admin message |
