@smoke
@cms
@javascript
Feature: CMS pages navigation
  As a user
  I want to navigate through the Clark site using links on the pages

  Scenario: User opens Clark home page and goes to "how it works" page
    Given user navigates to home page
    Then  user is on the home page

    When user clicks on "So funktioniert’s" link
    Then user is on the how it works page
    And  user sees that the page title is "CLARK - So funktioniert's"

  Scenario Outline: User opens Clark home page and navigates through AGB, ueber-uns, Impressum and Datenschutz pages
    Given user navigates to home page
    Then  user is on the home page

    When user clicks on "<navigation_link>" link
    Then user is on the <pagename> page
    And  user sees that the page title is "<pagetitle>"
    And user sees text "<text>"

    Examples:
      | navigation_link | pagename        | pagetitle                                      | text           |
      | Über uns        | ueber-uns       | CLARK - Über uns                               | Unsere Mission |
      | AGB             | agb             | Allgemeine Geschäftsbedingungen - AGB \| Clark | Clark GmbH     |
      | Impressum       | impressum       | Impressum I Clark                              | Clark GmbH     |
      | Datenschutz     | datenschutz     | Erklärung zum Datenschutz \| Clark             | Clark GmbH     |
