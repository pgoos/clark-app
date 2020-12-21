@javascript
@desktop_only
Feature: Assign message to a consultant on work item page
  As an admin
  I want to assign an incoming message to a consultant on work items page

  @stagings_only
  Scenario: Assign incoming message to a consultant
    Given admin is logged in ops ui
    When admin clicks on "Aufgaben" link
    Then admin is on the work items page

    # open incoming messages view and assign message
    When admin clicks on "Eingang" link
    Then admin sees populated incoming messages table on page
    And admin sees text "Ungelesene Nachrichten"

    When admin assigns the first incoming message to "Automation Admin"
    Then admin sees first incoming message assigned to "Automation Admin"
