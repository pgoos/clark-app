@javascript
@smoke
Feature: Self-service customer deletes a contract
  As a self-service customer
  I want to delete my contract

  Background: Self-service customer signs in and opens contract details
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    And user is a self service customer with a contract
    And user logs in with the credentials
    And user closes "new demand check" modal

    When user clicks on contract card "Privathaftpflicht - Allianz Versicherung"
    Then user is on the clark 2 contract details page

  Scenario: Self-service customer signs in and deletes a contract with a document
    When user uploads contract document
    Then user sees "Geschafft!" modal

    When user closes "Geschafft!" modal
    And  user clicks on "Vertrag entfernen" button
    Then user sees "Bist du dir sicher?" modal

    When user clicks on "Ja, Vertrag entfernen" button
    Then user is on the clark 2 contract adding exploration page
    And  user sees text "Volle Übersicht"
    And  user sees that "Jetzt starten" link is visible

  Scenario: Self-service customer signs in and deletes a contract without a document
    When user clicks on "Vertrag entfernen" button
    Then user sees "Bist du dir sicher?" modal

    When user clicks on "Ja, Vertrag entfernen" button
    Then user is on the clark 2 contract adding exploration page
    And  user sees text "Volle Übersicht"
    And  user sees that "Jetzt starten" link is visible
