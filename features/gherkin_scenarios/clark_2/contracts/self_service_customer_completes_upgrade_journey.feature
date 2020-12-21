@javascript
Feature: Self-service customer signs in and completes upgrade journey
  As a self-service customer
  I want to complete the upgrade journey and become a mandate customer

  @smoke
  Scenario: Self-service customer signs in and completes upgrade journey
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    And user is a self service customer with a contract
    And user logs in with the credentials
    And user closes "new demand check" modal
    And user is on the manager page

    # Initiate 'upgrade' process
    When user clicks messenger icon
    Then user sees messenger window opened

    When user clicks on "CLARK Concierge entdecken" link
    Then user is on the clark 2 customer upgrade page

    When user clicks on "Jetzt CLARK Concierge nutzen" button
    Then user is on the clark 2 customer upgrade profile page

    When user fills the profiling form with their data
    And  user clicks on "Weiter" button
    Then user is on the clark 2 customer upgrade signature page
    And  user sees text "Einverständnis geben"

    When user clicks on "insign" button
    And  user sees text "Bitte unterschreibe hier mit deiner Maus"
    And  user enters their signature
    And  user clicks on "Weiter" button
    Then user sees that "Bestätigen" button is visible

    When user clicks on "Bestätigen" button
    Then user is on the clark 2 customer upgrade phone verification page
    And  user enters their verification token data
    And  user clicks on "CLARK Concierge entdecken" button
