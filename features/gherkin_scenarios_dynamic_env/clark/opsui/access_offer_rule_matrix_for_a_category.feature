@ignore
@smoke
@javascript
@desktop_only
Feature: Check Offer Rule Matrix in OPS UI
  As an admin
  I want to be sure that all required sections of offer rule matrix are present in OPS UI pages

  @requires_mandate
  Scenario: Access offer rule matrix for Privathaftpflichtversicherung
    # open OPS UI and navigate to plan filters page
    Given admin is logged in ops ui
    When admin clicks on "Automatisierung" link
    Then admin is on the plan filters page

    # open automation page view and view categories
    When admin clicks on "Angebotsregeln" link
    Then admin is on the offer automations page

    # check admin can see all available categories
    # TODO replace these lines with table step in the future
    And admin sees text "Privathaftpflichtversicherung"
    And admin sees text "Zahnzusatz"
    And admin sees text "Reiseversicherung V2"
    And admin sees text "Reiseversicherung"
    And admin sees text "Unfallversicherung V2"
    And admin sees text "Tierhalter-Haftpflicht"
    And admin sees text "Rechtsschutz"
    And admin sees text "Unfallversicherung"

    # check that all required sections are present
    When admin clicks on "Privathaftpflichtversicherung" link
    Then admin is on the Offer automation insurance detail page
    And admin sees "Regeln" page section
    # TODO verify that table has non empty rows
    And admin sees text "Name"
    And admin sees text "Pläne"
