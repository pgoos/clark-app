@javascript
@desktop_only
@smoke
Feature: Check customer uploaded contract documents work item in opsui
  As an admin
  I want to be able to see and interact with clark 2.0 contract documents uploaded by customers

  Background: User adds a contract and admin logs into OPS UI
    Given user is as the following
      | first_name |
      | Clark 2.0  |
    And user is a self service customer with a contract

    When user logs in with the credentials
    And user closes "new demand check" modal
    Then user is on the manager page
    And  user sees contract card "Privathaftpflicht - Allianz Versicherung"

    When user clicks on contract card "Privathaftpflicht"
    Then user is on the clark 2 contract details page

    When user uploads contract document
    Then user sees "Geschafft!" modal

    #log into OPS UI and navigate to the work item
    Given admin is logged in ops ui

    When admin clicks on "Aufgaben" link
    Then admin is on the work items page

    When admin clicks on "Uploads zu Produkten" link
    Then admin sees populated customer uploaded contract documents table on page

  Scenario: check clark2 customer uploaded documents appear in the customer uploaded contract documents work item
    Given admin sees test contract id in customer uploaded contract documents table

    When admin clicks on the test contract id in a table
    Then admin is on the product_details page

  Scenario: Ops agent accepts documents in the customer uploaded contract documents work item
    Given admin sees test contract id in customer uploaded contract documents table

    When admin clicks on "thumbs up" button for test contract id in customer uploaded contract documents table
    Then admin does not see test contract id in customer uploaded contract documents table

  Scenario: Ops agent requests changes to document in the customer uploaded contract documents work item
    Given admin sees test contract id in customer uploaded contract documents table

    When admin clicks on "Rückfrage" button for test contract id in customer uploaded contract documents table
    Then admin sees text "Rückfrage zu Vertrag"

    When admin clicks on the "Rückfrage senden" button and accept confirmation popup
    Then admin does not see test contract id in customer uploaded contract documents table
