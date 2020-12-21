@javascript
@desktop_only
Feature: Create a new plan in OPS UI
  As an admin
  I want to be able to create a new plan

  Background:
    Given admin is logged in ops ui
    When admin clicks on "Tarife" link
    Then admin is on the plans page

  Scenario Outline: Create a new plan
    When admin clicks on "Tarif hinzufügen" link
    And admin is on the new plan page
    And admin enters <name> into Name input field
    And admin selects <category> as the plan category
    And admin selects <group> as the plan group
    And admin enters <price> into Prämie input field
    And admin selects <period> as the plan premium period
    And admin clicks on "Anlegen" button

    Then admin sees text "Tarif wurde erfolgreich erstellt."

  Examples:
    | name                 | category            | group | price | period      |
    | "Cucumber test Plan" | "Privathaftpflicht" | "ACE" | "10"  | "monatlich" |
